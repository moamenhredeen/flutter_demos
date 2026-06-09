# Book Search — declarative pagination with Riverpod

Infinite-scroll search over the [Open Library Search API](https://openlibrary.org/dev/docs/api/search), built on one idea:

> **A page of results is just a value, identified by `(query, page)`. Let providers own values; let rows ask for the value they need.**

There is no scroll listener, no `loadMore()`, no accumulated list, and no paging state machine. Scrolling *is* the pagination.

> This README explains how *this implementation* works. The decision record — alternatives
> tried, their bugs, and the portable rules — lives in
> [docs/patterns/pagination.md](../../docs/patterns/pagination.md).

## The pattern

```dart
typedef BookPageRequest = ({String query, int page});

final bookSearchPageProvider = FutureProvider.autoDispose
    .family<OpenLibrarySearchResponse, BookPageRequest>((ref, request) async {
  // fetch request.page of request.query, with cancellation + a short cache
});
```

One `FutureProvider.autoDispose.family` instance per **page of a specific query**. The list sizes itself from the total match count, and every visible row watches the provider for the page its index falls into. Watching a provider that doesn't exist yet creates it, which starts the fetch — so pages load exactly when their first row scrolls into view.

### Why the query is part of the family key

The tempting alternative is a family keyed by page number only, with the provider watching a query provider internally:

```dart
// The shape we deliberately avoided:
final pageProvider = FutureProvider.autoDispose.family<Response, int>((ref, page) {
  final query = ref.watch(queryProvider); // ← mutable dependency
  ...
});
```

That makes every cache entry *mutable*: changing the query invalidates and refetches every alive page, and during the transition the UI can show rows from two different searches at once (page 1 already showing the new query, page 2 still showing the old one).

With `(query, page)` as the key, every cache entry is **immutable** — `("dune", 3)` means the same thing forever:

- A new query can never invalidate, refetch, or interleave with the previous query's pages. Cross-query mixing is impossible *by construction*, not by careful guarding.
- Flipping back to a recent query is served from cache instantly.
- There is nothing to reset and no transition state to manage.

This is the general rule the demo exists to illustrate: **parameters that identify a result belong in the family key; providers should not watch mutable state that changes what their cached value means.**

### Why not an accumulating `AsyncNotifier` + `loadMore()`?

The previous iteration of this demo used the imperative shape: an `AsyncNotifier` holding `List<Doc> books` plus `page / hasMore / isLoadingMore` flags, fed by a `ScrollController` listener calling `loadMore()`. It worked, but every bug it had was structural:

| Bug | Root cause |
|---|---|
| Scrolling during a query change appended the *new* query's page N to the *old* query's list | Riverpod keeps the previous value while rebuilding (`AsyncLoading` with previous data), so `loadMore`'s guards passed against stale state |
| Stale `loadMore` continuation threw after the rebuild | Riverpod 3 recreates notifiers on rebuild; the old notifier's `state =` is invalid |
| Stuck at page 1 on tall windows | First page didn't fill the viewport → no scroll events → trigger never fired |
| Auto-loading cascade after a query change | Scroll offset clamped near the bottom of the new, shorter list |

All of these come from the same place: *mutable accumulated state plus imperative triggers that race against rebuilds*. The declarative shape has no accumulated state and no triggers, so this bug class doesn't exist in it.

The imperative shape is still the right tool for **cursor-based APIs** (where fetching page N+1 requires a token from page N, so results must accumulate sequentially). Open Library is offset-based, so we don't pay that complexity here.

## How it works, exactly

### 1. Typing → committed query

`BookSearchQuery` (a plain `Notifier<String>`) debounces input: `set()` arms a 400 ms timer on every keystroke, `submit()` (keyboard action) commits immediately. Only the *committed* value lives in `bookSearchQueryProvider`; widgets never see intermediate keystrokes, so no request is fired per keypress.

### 2. Sizing the list

`BookSearchResults` watches the committed query:

- empty → idle hint, nothing fetched;
- otherwise it watches **page 1**: `bookSearchPageProvider((query: query, page: 1))`.

Page 1 plays a double role: it is the first page of rows *and* it carries `numFound`, the total match count, which becomes the list length:

```dart
final total = min(first.numFound, kBookMaxResults); // capped at 1 000

ListView.builder(
  key: ValueKey(query), // new query = new list: fresh elements, scroll at top
  itemCount: total,
  itemBuilder: (context, index) => BookPageRow(query: query, index: index),
)
```

Because `itemCount` is the real total, the scrollbar is honest and the list simply *ends* at the last result — no "load more" footer, no end-of-list sentinel.

The `ValueKey(query)` matters: a new query replaces the list element entirely, which resets the scroll position to the top and unmounts every old row in one step.

### 3. Rows pull their page

`BookPageRow` maps its index to a page and watches it:

```dart
final page = index ~/ kBookPageSize + 1;           // 20 per page, 1-based
final pageAsync = ref.watch(bookSearchPageProvider((query: query, page: page)));
```

- **loading** → skeleton tile;
- **error** → error tile with a retry button (`ref.invalidate` of just that page);
- **data** → the real `BookTile` for `index % kBookPageSize`.

`ListView.builder` only builds visible rows, so only the pages that are on screen (or just off it) are ever watched. Rows 0–19 *and* the results widget all watch the same page-1 entry — Riverpod deduplicates watchers of the same family argument, so that's one fetch, not twenty-one.

Each row is its own `ConsumerWidget` on purpose. The subscription belongs to the row element, so:

- a page arriving rebuilds only that page's rows, not the whole list;
- a row scrolled out of view releases its subscription immediately when the element unmounts. (Watching from the list's own `ref` inside `itemBuilder` — a common variant — pins every touched page's subscription to the list element until the next full list rebuild.)

### 4. Page lifecycle: fetch, cancel, cache

The provider body, in order:

```dart
final repository = ref.watch(openLibraryRepositoryProvider);

final token = CancelToken();
ref.onDispose(token.cancel);                 // dispose mid-flight = abort HTTP

final response = await repository.search(...);

final link = ref.keepAlive();                // taken only AFTER success
final timer = Timer(kBookPageCacheDuration, link.close);
ref.onDispose(timer.cancel);

return response;
```

The ordering encodes the lifecycle:

- **While fetching** there is no `keepAlive` link, so the provider is a plain `autoDispose`: if every watching row unmounts (user flings past the page, or the query changes and `ValueKey` unmounts the list), the provider is disposed → `onDispose` fires → the `CancelToken` aborts the in-flight HTTP request. Fast scrolling doesn't queue up dead downloads.
- **After success** the `keepAlive()` link suspends auto-dispose for `kBookPageCacheDuration` (2 min). Scrolling away and back, or returning to a recent query, hits this cache. The timer itself is cancelled in `onDispose` so rebuilds don't leak timers.
- **Failed pages are never kept alive** — only successful responses are cached.

### 5. Errors and retries

Riverpod 3 auto-retries failed providers by default (exponential backoff, 200 ms → 6.4 s, up to 10 attempts), so an error row usually heals itself. The retry buttons (full-screen for page 1, per-row otherwise) just `ref.invalidate(...)` the one failed page to skip the backoff wait.

Both `when()` calls set `skipLoadingOnRefresh: false`, so a retry visibly drops back to the spinner/skeleton instead of freezing on the stale error view while the refetch runs.

A cancelled request (`DioException` of type `cancel`) never becomes provider state — the provider is already disposed or rebuilding when it fires — so cancellations are neither shown nor retried.

### 6. Defensive details

- **Count drift / deep-paging cap**: if a page returns fewer docs than `numFound` promised, missing rows render as a *fixed-height* gap (`SizedBox(height: 56)`), not `SizedBox.shrink()`. A run of zero-height rows would make the viewport build through dozens of rows — and request dozens of pages — in a single frame.
- **`kBookMaxResults` (1 000)**: Open Library degrades on deep paging, and a 400 000-row scrollbar is useless anyway.

## File map

| File | Role |
|---|---|
| `book_search_providers.dart` | Debounced query notifier; `(query, page)` page family; tuning constants |
| `book_search_screen.dart` | Scaffold + search app bar wiring input to the query notifier |
| `widgets/book_search_results.dart` | Idle/loading/error routing, result count, the keyed `ListView` |
| `widgets/book_page_row.dart` | index → page mapping, per-row watch, skeleton/error/data states |
| `widgets/book_tile.dart` | Presentation: cover, title, author · year |
| `widgets/book_tile_skeleton.dart` | Loading placeholder row |

## Limits of the pattern

- **Cursor/token pagination doesn't fit** — page N+1 would need page N's value, but family entries are independent. Use an accumulating notifier there (guarded with `state.isLoading` checks and Riverpod 3's `ref.mounted` after every `await`).
- **Jump-to-page UIs** work trivially (any `(query, page)` is directly addressable) — a bonus over the accumulating shape, where reaching page 50 means loading 49 pages first.
- **Whole-result refresh** is one call: `ref.invalidate(bookSearchPageProvider)` drops every cached page of every query.
