import 'dart:async';

import 'package:flutter_demos/data/open_library/open_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Items per page — the `limit` sent to the Open Library search API.
const kBookPageSize = 20;

/// Open Library caps deep paging, and a five-digit scrollbar is useless
/// anyway; the list never exposes more than this many rows.
const kBookMaxResults = 1000;

/// How long a fetched page stays cached once nothing watches it anymore.
const kBookPageCacheDuration = Duration(minutes: 2);

/// The committed search query, debounced so typing doesn't fire a request per
/// keystroke. The UI calls [BookSearchQuery.set] on every edit; consumers
/// watch the committed value via [bookSearchQueryProvider].
class BookSearchQuery extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  /// Commit [value] after a short pause in typing.
  void set(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => state = value.trim(),
    );
  }

  /// Commit immediately (e.g. on keyboard submit), bypassing the debounce.
  void submit(String value) {
    _debounce?.cancel();
    state = value.trim();
  }
}

final bookSearchQueryProvider =
    NotifierProvider<BookSearchQuery, String>(BookSearchQuery.new);

/// One page of one search — the family key of [bookSearchPageProvider].
typedef BookPageRequest = ({String query, int page});

/// One page of search results, keyed by `(query, page)`.
///
/// The query is part of the key on purpose: every cache entry is immutable.
/// Typing a new query just points the UI at different entries — it can never
/// invalidate or interleave with the previous query's pages, and flipping
/// back to a recent query within [kBookPageCacheDuration] is served from
/// cache. (Watching a query provider here instead would invalidate every
/// cached page on each query change.)
///
/// Lifecycle of a page:
/// - fetched lazily when the first visible row watches it;
/// - cancelled via [CancelToken] if all watchers disappear mid-flight (the
///   user flings past it) — `keepAlive` is taken only *after* the fetch
///   succeeds, so in-flight pages still auto-dispose and abort;
/// - cached for [kBookPageCacheDuration] after success, then released.
///
/// Failures: Riverpod 3 auto-retries failed providers with exponential
/// backoff, so an error row usually heals itself; the row's manual retry
/// button invalidates the page to skip the backoff wait.
final bookSearchPageProvider = FutureProvider.autoDispose
    .family<OpenLibrarySearchResponse, BookPageRequest>((ref, request) async {
  final repository = ref.watch(openLibraryRepositoryProvider);

  final token = CancelToken();
  ref.onDispose(token.cancel);

  final response = await repository.search(
    request.query,
    page: request.page,
    limit: kBookPageSize,
    cancelToken: token,
  );

  final link = ref.keepAlive();
  final timer = Timer(kBookPageCacheDuration, link.close);
  ref.onDispose(timer.cancel);

  return response;
});
