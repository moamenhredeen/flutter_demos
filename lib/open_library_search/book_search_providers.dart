import 'dart:async';

import 'package:flutter_demos/data/open_library/open_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_search_state.dart';

/// Current search query, debounced so typing doesn't fire a request per
/// keystroke. The UI calls [SearchQuery.set]; [bookSearchProvider] watches the
/// committed value.
class SearchQuery extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  /// Debounced setter — commits [value] after a short pause in typing.
  void set(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => state = value.trim(),
    );
  }

  /// Commit immediately (e.g. on submit), bypassing the debounce.
  void submit(String value) {
    _debounce?.cancel();
    state = value.trim();
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQuery, String>(SearchQuery.new);

/// Paginated book search over the Open Library API.
///
/// The first page loads in [build] (surfaced via the outer [AsyncValue]).
/// Subsequent pages are appended by [loadMore], tracked by
/// [BookSearchState.isLoadingMore] so the list stays visible while paging.
///
/// Each network call uses a [CancelToken] tied to `ref.onDispose`, so when the
/// query changes or the screen is left, in-flight requests are cancelled.
class BookSearchNotifier extends AsyncNotifier<BookSearchState> {
  static const _pageSize = 20;

  @override
  Future<BookSearchState> build() async {
    final query = ref.watch(searchQueryProvider);
    if (query.isEmpty) return const BookSearchState();

    final res = await _fetch(query, page: 1);
    return BookSearchState(
      books: res.docs,
      page: 1,
      numFound: res.numFound,
      hasMore: res.docs.isNotEmpty && res.docs.length < res.numFound,
    );
  }

  /// Load the next page and append it. No-op if already loading, at the end,
  /// or before the first page has loaded.
  Future<void> loadMore() async {
    if (!state.hasValue) return;
    final current = state.requireValue;
    if (!current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );

    final query = ref.read(searchQueryProvider);
    final nextPage = current.page + 1;
    try {
      final res = await _fetch(query, page: nextPage);
      final books = [...current.books, ...res.docs];
      state = AsyncData(
        current.copyWith(
          books: books,
          page: nextPage,
          numFound: res.numFound,
          hasMore: res.docs.isNotEmpty && books.length < res.numFound,
          isLoadingMore: false,
        ),
      );
    } on Object catch (e) {
      // Cancelled (query changed / disposed): drop silently, new build wins.
      if (OpenLibraryException.isCancellation(e)) return;
      state = AsyncData(current.copyWith(isLoadingMore: false, loadMoreError: e));
    }
  }

  /// Retry the last failed [loadMore].
  Future<void> retryLoadMore() => loadMore();

  Future<OpenLibrarySearchResponse> _fetch(String query, {required int page}) {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    return ref
        .read(openLibraryRepositoryProvider)
        .search(query, page: page, limit: _pageSize, cancelToken: token);
  }
}

final bookSearchProvider =
    AsyncNotifierProvider<BookSearchNotifier, BookSearchState>(
  BookSearchNotifier.new,
);
