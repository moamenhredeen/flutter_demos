import 'package:flutter/material.dart';
import 'package:flutter_demos/widgets/search_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'book_search_providers.dart';
import 'widgets/book_search_results.dart';

/// Open Library search with lazily-paged, infinitely-scrolling results.
///
/// Pagination is fully declarative: no scroll listener, no `loadMore`. The
/// list sizes itself from the total match count, each row watches the
/// `(query, page)` provider it belongs to, and a page is fetched when its
/// first row scrolls into view. See [bookSearchPageProvider].
class BookSearchScreen extends ConsumerStatefulWidget {
  const BookSearchScreen({super.key});

  @override
  ConsumerState<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends ConsumerState<BookSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        controller: _searchController,
        hintText: 'Search books, e.g. "dune"',
        onChanged: (v) => ref.read(bookSearchQueryProvider.notifier).set(v),
        onSubmitted: (v) =>
            ref.read(bookSearchQueryProvider.notifier).submit(v),
        onBack: () => context.go('/home'),
      ),
      body: const BookSearchResults(),
    );
  }
}
