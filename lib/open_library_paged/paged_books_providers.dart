import 'dart:async';

import 'package:flutter_demos/data/open_library/open_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Items per page — matches the `limit` sent to the Open Library search API.
const kPagedPageSize = 20;

/// Debounced search query for the paged demo.
class PagedQuery extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void set(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => state = value.trim(),
    );
  }

  void submit(String value) {
    _debounce?.cancel();
    state = value.trim();
  }
}

final pagedQueryProvider =
    NotifierProvider<PagedQuery, String>(PagedQuery.new);

/// One page of search results, keyed by 1-based page number.
///
/// This is the Riverpod pagination case-study shape: a single
/// `autoDispose.family` provider per page. The list `watch`es a page only when
/// a row from it scrolls into view, so pages are fetched lazily and freed when
/// scrolled away — no `loadMore`, no scroll listener.
///
/// Every page watches [pagedQueryProvider], so changing the query rebuilds all
/// pages (and cancels their in-flight requests via the [CancelToken]).
final booksPageProvider = FutureProvider.autoDispose
    .family<OpenLibrarySearchResponse, int>((ref, page) async {
  final query = ref.watch(pagedQueryProvider);
  if (query.isEmpty) {
    return const OpenLibrarySearchResponse(numFound: 0, start: 0, docs: []);
  }

  // Keep a recently-viewed page briefly so scrolling back doesn't refetch.
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 1), link.close);

  final token = CancelToken();
  ref.onDispose(token.cancel);

  return ref.watch(openLibraryRepositoryProvider).search(
        query,
        page: page,
        limit: kPagedPageSize,
        cancelToken: token,
      );
});
