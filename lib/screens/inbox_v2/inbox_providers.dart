import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_demos/data/gtd.dart';
import 'package:flutter_demos/pagination/paged_async_notifier.dart';
import 'package:flutter_demos/pagination/paged_state.dart';

/// Screen-level filter. The paged notifier `ref.watch`es this in build(),
/// so changing the filter rebuilds it: pagination restarts at page one and
/// the previous generation's in-flight request is cancelled — no plumbing.
class InboxEnergyFilter extends Notifier<GtdEnergy?> {
  @override
  GtdEnergy? build() => null;

  void set(GtdEnergy? value) => state = value;
}

final inboxEnergyFilterProvider =
    NotifierProvider<InboxEnergyFilter, GtdEnergy?>(InboxEnergyFilter.new);

/// PRIMARY: cursor pagination. A cursor is anchored to the last item, not to
/// a count, so concurrent inserts/deletes can't duplicate or skip rows — no
/// dedupe needed (itemKey stays null).
class InboxNotifier extends PagedAsyncNotifier<GtdTask, String> {
  static const _pageSize = 20;

  late GtdRepository _repo;
  GtdEnergy? _energy;

  @override
  Future<PagedState<GtdTask, String>> build() {
    // ref.watch is only legal inside build(): capture dependencies into
    // fields here; fetchPage (called by loadMore between builds) uses them.
    _repo = ref.watch(gtdRepositoryProvider);
    _energy = ref.watch(inboxEnergyFilterProvider);
    return super.build();
  }

  @override
  Future<PageResult<GtdTask, String>> fetchPage(
    String? cursor,
    CancelToken cancelToken,
  ) async {
    final page = await _repo.getTasksCursor(
      limit: _pageSize,
      cursor: cursor,
      status: GtdTaskStatus.inbox,
      energy: _energy,
      cancelToken: cancelToken,
    );
    return PageResult(
      items: page.items,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }
}

final inboxProvider =
    AsyncNotifierProvider.autoDispose<InboxNotifier,
        PagedState<GtdTask, String>>(
  InboxNotifier.new,
  // Riverpod 3 gotcha: providers auto-retry failed builds by default.
  // Disable it so the first-load error screen (and its Retry button) is
  // deterministic instead of silently refetching with backoff.
  retry: pagedNoRetry,
);

/// OFFSET VARIANT: cursor type is "next page number".
/// Demonstrates (a) mapping GtdOffsetPage onto PageResult and (b) dedupe
/// against offset drift.
class InboxOffsetNotifier extends PagedAsyncNotifier<GtdTask, int> {
  static const _pageSize = 20;

  late GtdRepository _repo;

  @override
  Future<PagedState<GtdTask, int>> build() {
    _repo = ref.watch(gtdRepositoryProvider);
    return super.build();
  }

  @override
  Future<PageResult<GtdTask, int>> fetchPage(
    int? cursor,
    CancelToken cancelToken,
  ) async {
    final pageNumber = cursor ?? 1;
    final page = await _repo.getTasks(
      page: pageNumber,
      perPage: _pageSize,
      status: GtdTaskStatus.inbox,
      cancelToken: cancelToken,
    );
    return PageResult(
      items: page.items,
      nextCursor: pageNumber + 1,
      // Trust the server's page math over `items.length == perPage`: a full
      // last page would cost one extra (empty) request, and a short page
      // mid-stream — possible while rows are being deleted — would silently
      // truncate the list.
      hasMore: page.page < page.pages,
    );
  }

  /// Offset drift: an insert/delete before our window shifts rows across
  /// page boundaries, so page N+1 can re-serve the tail of page N. Dropping
  /// already-seen ids keeps the list visually sane. (Drift can also SKIP
  /// rows; only a refresh truly heals an offset-paged list.)
  @override
  Object? itemKey(GtdTask item) => item.id;
}

final inboxOffsetProvider =
    AsyncNotifierProvider.autoDispose<InboxOffsetNotifier,
        PagedState<GtdTask, int>>(
  InboxOffsetNotifier.new,
  retry: pagedNoRetry,
);
