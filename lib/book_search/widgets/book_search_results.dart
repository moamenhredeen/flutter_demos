import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../book_search_providers.dart';
import 'book_page_row.dart';

/// Results area: routes between the idle / first-page / error / data states,
/// then renders the paged list.
///
/// Only page 1 is watched here — it answers "how many results?" and thereby
/// sizes the list. Rows watch their own page providers (rows 0..19 also watch
/// page 1, which deduplicates to the same cached entry, not a refetch).
class BookSearchResults extends ConsumerWidget {
  const BookSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(bookSearchQueryProvider);
    if (query.isEmpty) {
      return const Center(child: Text('Type to search Open Library'));
    }

    final firstPage =
        ref.watch(bookSearchPageProvider((query: query, page: 1)));

    return firstPage.when(
      // On retry-after-error, drop back to the spinner instead of keeping the
      // stale error view while the refetch runs.
      skipLoadingOnRefresh: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _FirstPageError(query: query, message: '$error'),
      data: (first) {
        if (first.numFound == 0) {
          return Center(child: Text('No results for "$query"'));
        }

        final total = min(first.numFound, kBookMaxResults);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${first.numFound} results',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                // A new query is a new list: fresh row elements and scroll
                // position back at the top.
                key: ValueKey(query),
                itemCount: total,
                itemBuilder: (context, index) =>
                    BookPageRow(query: query, index: index),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Full-screen error for a failed first page, with retry.
class _FirstPageError extends ConsumerWidget {
  const _FirstPageError({required this.query, required this.message});

  final String query;
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
              onPressed: () => ref.invalidate(
                bookSearchPageProvider((query: query, page: 1)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
