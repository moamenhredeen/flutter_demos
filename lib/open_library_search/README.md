# Open Library Search

Infinite-scroll search over the [Open Library](https://openlibrary.org/developers/api)
search API. This demo shows the common Riverpod pattern for paginated lists with
debounced input and request cancellation.

## Files

| File | Role |
| --- | --- |
| `open_library_search_screen.dart` | The screen. Owns the `ScrollController`, renders the search field and switches on the `AsyncValue`. |
| `book_search_providers.dart` | `searchQueryProvider` (debounced query) + `bookSearchProvider` (paginated `AsyncNotifier`). |
| `book_search_state.dart` | Immutable `BookSearchState`: accumulated books + paging flags. |
| `widgets/book_tile.dart` | One result row. |
| `widgets/search_results.dart` | Count header + `ListView` + paging footer. |
| `widgets/load_more_footer.dart` | Trailing item: loader / retry / end-of-list. |
| `widgets/search_error_view.dart` | First-page error state with retry. |

The repository, models and Dio client live in `lib/data/open_library` — this
folder only holds the screen and its state.

## The pattern

### 1. Query is its own provider, debounced

`searchQueryProvider` is a `Notifier<String>`. The text field calls `set()` on
every keystroke; `set()` debounces (400 ms) before committing the value, so we
don't fire a request per character. `submit()` commits immediately (on enter).

```dart
onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
onSubmitted: (v) => ref.read(searchQueryProvider.notifier).submit(v),
```

### 2. One AsyncNotifier owns the whole paged list

`bookSearchProvider` is an `AsyncNotifier<BookSearchState>`:

- **`build()`** `watch`es the query and loads **page 1**. Because it watches the
  query, changing the query automatically re-runs `build()` and resets paging.
  The first-page load and error are surfaced through the *outer* `AsyncValue`.
- **`loadMore()`** fetches the next page and **appends** to `state.books`. While
  it runs, `state.isLoadingMore` is `true` so the existing list stays on screen
  (we don't flip the whole screen back to a spinner). A failure sets
  `loadMoreError` and keeps the loaded books, so the footer can offer a retry.

`BookSearchState` carries everything the UI needs: `books`, `page`, `numFound`,
`hasMore`, `isLoadingMore`, `loadMoreError`.

### 3. Cancellation via CancelToken + ref.onDispose

Every fetch creates a Dio `CancelToken` registered with `ref.onDispose`:

```dart
final token = CancelToken();
ref.onDispose(token.cancel);
```

Riverpod runs `onDispose` callbacks both when the provider is destroyed (screen
left) **and** when it recomputes (query changed). So a stale page request is
cancelled the moment the query changes or the screen closes. Cancellations throw
a `DioException` of type `cancel`, which `loadMore` detects via
`OpenLibraryException.isCancellation` and drops silently — the new `build()`
wins.

### 4. Scroll drives loadMore

The screen's `ScrollController` listener calls `loadMore()` when within 300px of
the bottom. `loadMore()` is a no-op if already loading, at the end, or before
page 1 — so spamming the call is safe.

```dart
void _onScroll() {
  final p = _scrollController.position;
  if (p.pixels >= p.maxScrollExtent - 300) {
    ref.read(bookSearchProvider.notifier).loadMore();
  }
}
```

### 5. UI is a switch on AsyncValue

```dart
switch (searchAsync) {
  AsyncLoading() when !searchAsync.hasValue => spinner,   // first page only
  AsyncError(:final error) => SearchErrorView(...),        // first-page error
  _ => SearchResults(...),                                 // data (incl. paging)
}
```

Subsequent-page state lives inside `BookSearchState` (the footer), not the outer
`AsyncValue` — that's what keeps the list visible while paging.

## Why these choices

- **State in the notifier, navigation in the widget.** Providers never touch
  `BuildContext`; the screen reads state and renders. Keeps the notifier
  testable.
- **Watch the query instead of manual reset.** No imperative "clear and reload"
  — `ref.watch` makes a query change rebuild page 1 for free.
- **Cancel through `onDispose`** rather than tracking tokens by hand; Riverpod's
  lifecycle does the bookkeeping.
