import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../book_search_providers.dart';
import 'book_tile.dart';
import 'book_tile_skeleton.dart';

/// One row of the paged list.
///
/// Watches the page provider its [index] falls into, so the page is fetched
/// when the row first becomes visible. Being its own [ConsumerWidget] keeps
/// the subscription scoped to the row: a page arriving rebuilds only that
/// page's rows, and scrolling a row out of view releases its subscription
/// immediately — which is what lets unwatched in-flight pages auto-dispose
/// and cancel their request.
class BookPageRow extends ConsumerWidget {
  const BookPageRow({super.key, required this.query, required this.index});

  final String query;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = index ~/ kBookPageSize + 1; // pages are 1-based
    final pageAsync =
        ref.watch(bookSearchPageProvider((query: query, page: page)));

    return pageAsync.when(
      // On retry-after-error, show the skeleton again instead of keeping the
      // stale error row while the refetch runs.
      skipLoadingOnRefresh: false,
      loading: () => const BookTileSkeleton(),
      error: (error, _) => _PageErrorTile(query: query, page: page),
      data: (response) {
        final indexInPage = index % kBookPageSize;
        // numFound promised more rows than the page delivered (count drift,
        // deep-paging cap). A fixed-height gap keeps the viewport from
        // building through a run of zero-height rows in a single frame.
        if (indexInPage >= response.docs.length) {
          return const SizedBox(height: 56);
        }
        return BookTile(book: response.docs[indexInPage]);
      },
    );
  }
}

/// Error row for one failed page; retry refetches just that page.
class _PageErrorTile extends ConsumerWidget {
  const _PageErrorTile({required this.query, required this.page});

  final String query;
  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.error_outline),
      title: Text('Failed to load page $page'),
      trailing: IconButton(
        tooltip: 'Retry',
        icon: const Icon(Icons.refresh),
        onPressed: () => ref.invalidate(
          bookSearchPageProvider((query: query, page: page)),
        ),
      ),
    );
  }
}
