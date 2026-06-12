import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show mustCallSuper, protected;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'paged_state.dart';

/// Riverpod 3 retries failed builds by default (10 tries, 200ms..6.4s
/// backoff). For a paged list that turns the full-screen error into a lie:
/// it silently refetches behind the Retry button. Pass this as `retry:` on
/// every paged provider so the user-facing Retry is the only retry path.
Duration? pagedNoRetry(int retryCount, Object error) => null;

/// Accumulating infinite-scroll notifier (the shape of Remi Rousselet's
/// official pull_to_refresh / Marvel pagination examples, generalized):
/// ONE provider owns the whole list plus its pagination bookkeeping.
///
/// `build()` fetches page one; [loadMore] appends pages in place. Refresh ==
/// rebuild: `ref.refresh`/`ref.invalidate` reruns build(), which restarts at
/// page one and — via the per-build [CancelToken] — aborts any in-flight
/// request of the previous generation.
abstract class PagedAsyncNotifier<T, C>
    extends AsyncNotifier<PagedState<T, C>> {
  /// Fetch one page; `cursor == null` means "first page". Implementations
  /// MUST forward [cancelToken] to the HTTP layer (every repository method
  /// in this codebase accepts one).
  @protected
  Future<PageResult<T, C>> fetchPage(C? cursor, CancelToken cancelToken);

  /// Identity used to drop duplicates when appending. Offset APIs re-serve
  /// rows when the dataset shifts between page fetches ("offset drift");
  /// return the item's id there. Return null (default) to disable, e.g. for
  /// keyset/cursor APIs, which cannot produce duplicates.
  @protected
  Object? itemKey(T item) => null;

  /// Cancellation must never surface as an error tile. Override when
  /// porting this pattern to a non-dio app.
  @protected
  bool isCancellation(Object error) =>
      error is DioException && error.type == DioExceptionType.cancel;

  /// One token per build() generation. `ref.onDispose` runs on BOTH rebuild
  /// (refresh / invalidate / dependency change) and final dispose, so the
  /// in-flight request of a stale generation is aborted exactly when that
  /// generation dies.
  late CancelToken _cancelToken;

  /// Bumped at every [build]. In-flight [loadMore]s stamp themselves with it
  /// so a completion from a dead generation can never touch fresh state —
  /// the notifier INSTANCE survives rebuilds (riverpod >= 3.0 stable), so
  /// instance fields alone don't distinguish generations.
  int _generation = 0;

  /// Concurrency dedupe for [loadMore]. Deliberately a field, NOT
  /// [PagedState.isLoadingMore]: the state flag can survive a failed refresh
  /// via `AsyncValue` retention, and a guard reading it would deadlock the
  /// footer — the stuck flag blocks the very call that could clear it.
  /// Reset by [build], so a new generation always starts unblocked.
  bool _busy = false;

  @override
  @mustCallSuper
  Future<PagedState<T, C>> build() async {
    // Subclasses with filters override build(), `ref.watch` their filter
    // providers there (watch is only legal inside build), stash the values
    // in fields, then call `super.build()`. A filter change then rebuilds
    // this provider => pagination restarts from page one automatically.
    final token = CancelToken();
    ref.onDispose(() => token.cancel('paged provider rebuilt/disposed'));
    _cancelToken = token;
    _generation++;
    _busy = false;

    final page = await fetchPage(null, token);
    return PagedState(
      items: page.items,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  /// Safe to spam from the UI (tile mounts, scroll listeners): dedupes
  /// concurrent calls via `isLoadingMore`, refuses to fire past the last
  /// page via `hasMore`, and stays quiet while a previous failure waits for
  /// an explicit [retryLoadMore].
  Future<void> loadMore() => _fetchNext(retryingAfterError: false);

  /// The error tile's Retry button — the only caller allowed to clear
  /// [PagedState.loadMoreError].
  Future<void> retryLoadMore() => _fetchNext(retryingAfterError: true);

  Future<void> _fetchNext({required bool retryingAfterError}) async {
    // Capture THIS generation's Ref. Riverpod >= 3.2.0: a stale captured Ref
    // reports `mounted == false` after a REBUILD as well as after a dispose,
    // whereas `this.ref` re-resolves to the live ref and would let a stale
    // continuation clobber the fresh generation's state.
    final ref = this.ref;
    if (!ref.mounted) return; // e.g. a post-frame callback after pop

    // A rebuild in flight (refresh, filter change) retains the OLD value
    // while the new page-1 request runs. Its cursor belongs to the dead
    // generation — appending through it would graft a stale page onto the
    // fresh list the moment the rebuild lands.
    if (state.isLoading) return;

    final current = state.value;
    if (current == null) return; // page one failed (or never ran)
    if (!current.hasMore) return; // never a wasted request past the end
    if (_busy) return; // dedupe concurrent triggers
    if (current.loadMoreError != null && !retryingAfterError) return;

    final gen = _generation; // capture: a rebuild bumps the field
    final token = _cancelToken; // capture: a rebuild swaps the field
    _busy = true;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );

    try {
      final page = await fetchPage(current.nextCursor, token);
      // Stale-generation guard: build() ran again while we were in flight.
      // The new generation owns state AND _busy now — touch neither.
      // (`ref.mounted` covers dispose, and rebuilds too on riverpod >= 3.2;
      // the generation stamp covers rebuilds on any version.)
      if (!ref.mounted || gen != _generation) return;
      _busy = false;
      final latest = state.value ?? current;
      state = AsyncData(
        PagedState(
          items: _append(latest.items, page.items),
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        ),
      );
    } catch (error) {
      if (!ref.mounted || gen != _generation) return;
      _busy = false;
      // A transport-level cancel that somehow reaches a live generation:
      // never an error tile. The next trigger simply refires.
      if (isCancellation(error)) return;
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }

  List<T> _append(List<T> existing, List<T> incoming) {
    if (incoming.isEmpty) return existing;
    if (itemKey(incoming.first) == null) return [...existing, ...incoming];
    final seen = {for (final item in existing) itemKey(item)};
    return [
      ...existing,
      ...incoming.where((item) => !seen.contains(itemKey(item))),
    ];
  }
}
