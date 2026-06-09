import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../book_search_providers.dart';
import '../book_search_state.dart';

/// Trailing list item: shows a loader while paging, a retry button on a
/// `loadMore` failure, or an end-of-list marker.
class LoadMoreFooter extends ConsumerWidget {
  const LoadMoreFooter({super.key, required this.state});

  final BookSearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton.icon(
            onPressed: () =>
                ref.read(bookSearchProvider.notifier).retryLoadMore(),
            icon: const Icon(Icons.refresh),
            label: const Text('Failed to load more — retry'),
          ),
        ),
      );
    }
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('— end of results —')),
      );
    }
    return const SizedBox(height: 48);
  }
}
