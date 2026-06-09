import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_demos/open_library_search/widgets/book_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../paged_books_providers.dart';
import 'book_tile_skeleton.dart';

/// Lazily-paged results list.
///
/// `itemCount` is the total match count (`numFound`). `ListView.builder` only
/// builds visible rows, and each row `watch`es the page provider it belongs to
/// — so pages load on demand as you scroll, with no scroll listener.
class PagedBookList extends ConsumerWidget {
  const PagedBookList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(pagedQueryProvider);
    if (query.isEmpty) {
      return const Center(child: Text('Type to search Open Library'));
    }

    // The first page also gives us the total count that sizes the list.
    final firstPage = ref.watch(booksPageProvider(1));

    return firstPage.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (first) {
        if (first.numFound == 0) {
          return Center(child: Text('No results for "$query"'));
        }
        // Open Library caps deep paging; keep the list to a sane length.
        final total = min(first.numFound, 1000);

        return ListView.builder(
          itemCount: total,
          itemBuilder: (context, index) {
            final page = index ~/ kPagedPageSize + 1; // 1-based
            final indexInPage = index % kPagedPageSize;

            // Reuse the already-loaded first page instead of re-watching it.
            final pageAsync = page == 1
                ? AsyncData(first)
                : ref.watch(booksPageProvider(page));

            return pageAsync.when(
              loading: () => const BookTileSkeleton(),
              error: (e, _) => ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text('Failed to load page $page'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.invalidate(booksPageProvider(page)),
                ),
              ),
              data: (resp) {
                if (indexInPage >= resp.docs.length) {
                  return const SizedBox.shrink();
                }
                return BookTile(book: resp.docs[indexInPage]);
              },
            );
          },
        );
      },
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(booksPageProvider(1)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
