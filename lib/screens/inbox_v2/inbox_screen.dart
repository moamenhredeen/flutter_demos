import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_demos/data/gtd.dart';
import 'package:flutter_demos/pagination/paged_state.dart';
import 'package:flutter_demos/pagination/paged_status_tile.dart';

import 'inbox_providers.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(inboxProvider);

    // Riverpod 3 gotcha: AsyncValue keeps previous data during rebuilds, so
    // a FAILED REFRESH arrives as AsyncError WITH a value. The list below
    // keeps rendering the stale items; surface the failure as a snackbar
    // instead of nuking a perfectly scrollable list.
    ref.listen(inboxProvider, (previous, next) {
      if (next.hasError && !next.isLoading && next.hasValue) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Refresh failed — list may be out of date'),
            ),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      // Order matters (same gotcha): while refreshing, state is AsyncLoading
      // WITH a value. Match `value` FIRST or every pull-to-refresh replaces
      // the list with skeletons (and loses the scroll position with it).
      body: switch (tasks) {
        AsyncValue(:final value?) => RefreshIndicator(
            // `ref.refresh(provider.future)` actually awaits the new first
            // page, so the indicator spins for the duration of the request.
            // (`ref.read(provider)` returns an AsyncValue SNAPSHOT
            // synchronously — awaiting it completes immediately; that was
            // the bug in the per-page-family version of this screen.)
            onRefresh: () async {
              try {
                // `final _ =` keeps the @useResult lint happy; the await is
                // the part we actually need.
                final _ = await ref.refresh(inboxProvider.future);
              } catch (_) {
                // Failure UX is handled by ref.listen above; catching here
                // only silences the unhandled-zone-error report.
              }
            },
            child: _TaskList(state: value),
          ),
        // Retry path: "Try again" invalidates, which makes the state
        // AsyncLoading WITH the retained error (AsyncValue keeps both).
        // Match loading BEFORE error, or the user stares at a frozen error
        // screen with zero feedback while the retry request runs.
        AsyncValue(isLoading: true) => const _FirstLoadSkeletons(),
        // FIRST-LOAD error: nothing to show, so it owns the whole screen.
        // Reached deterministically because the provider sets `retry:
        // pagedNoRetry` — otherwise Riverpod would auto-retry behind it.
        AsyncValue(:final error?) => _FirstLoadError(
            error: error,
            onRetry: () => ref.invalidate(inboxProvider),
          ),
        _ => const _FirstLoadSkeletons(),
      },
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.state});

  final PagedState<GtdTask, String> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      // Pull-to-refresh must work even when content doesn't fill the
      // viewport (short lists, empty state).
      physics: const AlwaysScrollableScrollPhysics(),
      // The status tile mounting IS the load-more trigger, so the viewport
      // cache extent doubles as the prefetch distance (default ~250px).
      // Raise it via `cacheExtent:` (renamed `scrollCacheExtent` on newer
      // Flutter) to start loading earlier.
      slivers: [
        if (state.isEmpty)
          // The single empty state: page one was empty and hasMore is false.
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyInbox(),
          )
        else
          SliverList.builder(
            itemCount: state.items.length + 1, // +1 = status/footer tile
            itemBuilder: (context, index) {
              if (index < state.items.length) {
                final task = state.items[index];
                return ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: Text(task.title),
                  subtitle: task.notes == null ? null : Text(task.notes!),
                );
              }
              return PagedStatusTile(
                hasMore: state.hasMore,
                isLoadingMore: state.isLoadingMore,
                error: state.loadMoreError,
                onLoadMore: () => ref.read(inboxProvider.notifier).loadMore(),
                onRetry: () =>
                    ref.read(inboxProvider.notifier).retryLoadMore(),
              );
            },
          ),
      ],
    );
  }
}

class _FirstLoadError extends StatelessWidget {
  const _FirstLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              '$error',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text('Inbox zero', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Pull down to check again',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FirstLoadSkeletons extends StatelessWidget {
  const _FirstLoadSkeletons();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      itemBuilder: (context, index) => const _SkeletonTile(),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width) => Container(
          width: width,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(double.infinity),
          const SizedBox(height: 8),
          bar(180),
        ],
      ),
    );
  }
}
