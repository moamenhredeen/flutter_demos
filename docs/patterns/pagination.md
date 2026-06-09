# Pagination + search (offset/page list APIs)

**Date:** 2026-06-10
**Versions:** flutter_riverpod 3.3.1 · dio 5.9.2 · go_router 17.3.0 · Dart SDK ^3.12.1
**Demo API:** Open Library `/search.json` (offset-based: `page` + `limit`, returns `numFound`)

## Verdict

**Declarative page-family pagination with the query inside the family key:**

```dart
typedef BookPageRequest = ({String query, int page});

final bookSearchPageProvider = FutureProvider.autoDispose
    .family<OpenLibrarySearchResponse, BookPageRequest>((ref, request) async { ... });
```

No scroll listener, no `loadMore()`, no accumulated list. The list takes its length from the
total match count; each visible row watches the provider of the page its index falls into;
watching creates the provider, which starts the fetch.

Live code: [`lib/book_search/`](../../lib/book_search/) (mechanics walkthrough in its
[README](../../lib/book_search/README.md)).

## Options tried

### 1. Accumulating `AsyncNotifier` + scroll listener + `loadMore()` — rejected

Commit `a5a70ae` (`lib/open_library_search/`, deleted from `main`).
`AsyncNotifier<BookSearchState>` holding `books / page / hasMore / isLoadingMore /
loadMoreError`, driven by a `ScrollController` listener firing `loadMore()` near the bottom.

Bugs found, all structural:

| Bug | Root cause |
|---|---|
| Scrolling during a query change appended the **new** query's page N to the **old** query's list (visible mixed results) | Riverpod keeps the previous value while rebuilding (`AsyncLoading` via `copyWithPrevious`), so `loadMore`'s `hasValue`/`hasMore` guards passed against stale state while `ref.read(query)` returned the new query |
| Stale `loadMore` continuation threw `StateError` into an unawaited future after a query change | Riverpod 3 recreates notifiers on rebuild; the old notifier's `state =` hits `_throwIfInvalidUsage()`. Second `state =` inside the `catch` threw again, uncaught |
| Stuck at page 1 when content didn't fill the viewport (tall desktop windows) | Trigger was scroll events; no overflow → no scroll events → `loadMore` never fired |
| Auto-load cascade after query change | Scroll offset clamped near the bottom of the new, shorter list re-triggered the listener |

Lesson: mutable accumulated state + imperative triggers race against provider rebuilds.
Every guard added is a patch over a structural problem.

### 2. Page-family watching a query provider — rejected

Commit `d1f6ef1` (`lib/open_library_paged/`, deleted from `main`).
`FutureProvider.autoDispose.family<Response, int>` keyed by page number only, with
`ref.watch(queryProvider)` inside, plus `ref.keepAlive()` + 1-minute timer taken **before**
the fetch.

| Bug | Root cause |
|---|---|
| "Cancelled when scrolled away" never happened (doc comment was false) | `keepAlive()` before the fetch blocks autoDispose → scrolled-past in-flight pages survived and downloaded to completion |
| Timer leak per rebuild | Keep-alive timer never cancelled in `onDispose`; every query commit spawned another orphan timer per page |
| Transient cross-query mixed list | Query watched inside the family → cache keyed by page only → query change invalidates all pages; with `when`'s default `skipLoadingOnRefresh: true`, page 1 showed new results while page 2+ still showed the old query's docs |
| Scroll position survived query change | No key on the list; `itemCount` jumped and the user landed mid-list of the new search |
| Whole-list rebuild on every page arrival; scrolled-away subscriptions released late | `ref.watch` inside `itemBuilder` using the outer widget's `ref` pins subscriptions to the list element |
| Potential request burst on short pages | Missing rows rendered `SizedBox.shrink()` → viewport builds through runs of zero-height rows in one frame |

Lesson: right shape, wrong details. The killer was the mutable dependency: a cache entry
whose *meaning* changes when another provider changes isn't a cache, it's a liability.

### 3. `(query, page)` family key — winner

Same declarative shape as option 2, three decisive corrections:

- **Query moved into the family key.** Every cache entry is immutable; a new query points the
  UI at different entries instead of invalidating existing ones. Cross-query mixing becomes
  impossible *by construction*. Flipping back to a recent query is a cache hit.
- **`keepAlive()` taken only after a successful fetch**, cancel token registered in
  `onDispose` first, cache timer cancelled in `onDispose`. In-flight pages cancel for real
  when all watchers unmount; only successes are cached (2 min).
- **Per-row `ConsumerWidget`** + **`ValueKey(query)` on the `ListView`**. Subscriptions scope
  to rows (page arrival rebuilds only its rows; unmount releases immediately), and a query
  change replaces the list element — scroll reset and mass-unmount in one step.

## When NOT to use this

- **Cursor/token APIs** (page N+1 needs a token from page N): independent family entries
  can't express the dependency. Use the accumulating-notifier shape, hardened:
  `if (state.isLoading) return;` guard (covers the refresh-with-previous-value window),
  `if (!ref.mounted) return;` after every `await` (Riverpod 3), committed query stored
  *inside* the state it produced, and a post-frame viewport-fill check.
- **Tiny finite lists** — just fetch once; pagination machinery isn't free.

Bonus over the accumulating shape: jump-to-page UIs are trivial — any `(query, page)` is
directly addressable without loading the pages before it.

## Rules to carry over

1. **Family key = identity of the result.** Never `ref.watch` mutable state inside a family
   provider if that state changes what the cached value *means*. If it identifies the result,
   it belongs in the key (records work as keys — value equality, no codegen).
2. **`keepAlive()` after success only**; `CancelToken` cancel registered in `onDispose`
   before the `await`; cache-expiry timer cancelled in `onDispose`. Order encodes lifecycle.
3. **Per-row `ConsumerWidget`** for lists whose rows watch providers — never the outer
   widget's `ref` inside `itemBuilder`.
4. **`ValueKey(identity)` on the list** when the dataset identity changes: free scroll reset,
   immediate unmount → immediate cancellation of now-irrelevant fetches.
5. **Riverpod 3 specifics:** notifiers are recreated on rebuild (`state =` from stale
   continuations throws — guard with `ref.mounted`); failed providers auto-retry by default
   (exponential backoff 200 ms → 6.4 s, max 10, `Exception`s only) — manual retry buttons
   should `invalidate` to skip the backoff; `AsyncValue` keeps previous data during rebuilds,
   so `hasValue` is *not* "not refreshing".
6. **Never render `SizedBox.shrink()` for placeholder rows** in a builder list — zero-height
   runs make the viewport build (and fetch) through many pages in one frame. Use a
   fixed-height gap.
7. **Debounce in the notifier, not the widget** — only committed queries become state;
   `submit()` bypasses the debounce for the keyboard action.
