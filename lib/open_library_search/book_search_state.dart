import 'package:flutter_demos/data/open_library/open_library.dart';

/// Immutable state for the paginated book search.
class BookSearchState {
  const BookSearchState({
    this.books = const [],
    this.page = 0,
    this.numFound = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  /// Books accumulated across all loaded pages.
  final List<OpenLibraryDoc> books;

  /// Highest page loaded so far (1-based; 0 = nothing loaded).
  final int page;

  /// Total matches reported by the API across all pages.
  final int numFound;

  /// Whether more pages remain to load.
  final bool hasMore;

  /// True while a *subsequent* page is loading (the first page uses the outer
  /// [AsyncValue] loading state instead).
  final bool isLoadingMore;

  /// Set when a `loadMore` call fails; the already-loaded [books] are kept so
  /// the UI can show them plus a retry affordance.
  final Object? loadMoreError;

  bool get isEmpty => books.isEmpty;

  BookSearchState copyWith({
    List<OpenLibraryDoc>? books,
    int? page,
    int? numFound,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return BookSearchState(
      books: books ?? this.books,
      page: page ?? this.page,
      numFound: numFound ?? this.numFound,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}
