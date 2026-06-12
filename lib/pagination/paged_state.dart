// For a pure-Dart (non-Flutter) package, import 'package:meta/meta.dart'
// instead — same annotations.
import 'package:flutter/foundation.dart' show immutable;

/// One fetched page, normalized so `PagedAsyncNotifier` doesn't care whether
/// the API is cursor- or offset-paged. `C` is the cursor type: `String` for
/// real cursors, `int` ("next page number") for offset APIs.
@immutable
class PageResult<T, C> {
  const PageResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;

  /// Cursor of the page after this one. Meaningless when [hasMore] is false.
  final C? nextCursor;

  final bool hasMore;
}

/// Accumulated infinite-scroll state. Lives *inside* `AsyncValue<PagedState>`:
///
/// - `AsyncLoading` (no value) -> first page in flight -> skeleton screen
/// - `AsyncError`   (no value) -> first page failed    -> full-screen retry
/// - `AsyncData(PagedState)`   -> list on screen; load-more progress/failure
///   lives INSIDE the data, so a failed page N never demotes pages 1..N-1
///   to a full-screen error.
@immutable
class PagedState<T, C> {
  const PagedState({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  /// All pages fetched so far, flattened.
  final List<T> items;

  /// Cursor of the *next* page; null when there is none (or for page one).
  final C? nextCursor;

  /// False once the API said "last page" — the single source of truth that
  /// prevents any request past the end.
  final bool hasMore;

  /// A next-page request is in flight (drives the footer spinner). Purely
  /// informational — the concurrency dedupe lives in the notifier, because
  /// this flag can go stale via `AsyncValue` retention when a refresh
  /// interrupts a load-more.
  final bool isLoadingMore;

  /// Last loadMore failure. Sticky: scroll triggers won't refire while it is
  /// set — only an explicit retry (or a refresh) clears it. This is what
  /// makes "exactly one error tile with one Retry button" possible.
  final Object? loadMoreError;

  /// The one true empty state: page one came back empty AND there is nothing
  /// more to fetch.
  bool get isEmpty => items.isEmpty && !hasMore;

  /// [nextCursor] is deliberately NOT copyable: a new cursor only ever
  /// arrives together with new items, i.e. via a fresh [PagedState].
  PagedState<T, C> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return PagedState(
      items: items ?? this.items,
      nextCursor: nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}
