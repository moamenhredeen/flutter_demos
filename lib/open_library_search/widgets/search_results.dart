import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../book_search_state.dart';
import 'book_tile.dart';
import 'load_more_footer.dart';

/// The scrollable results list: header count, book rows, and a paging footer.
///
/// The [scrollController] is owned by the screen, which uses it to drive
/// `loadMore` as the user nears the bottom.
class SearchResults extends ConsumerWidget {
  const SearchResults({
    super.key,
    required this.state,
    required this.query,
    required this.scrollController,
  });

  final BookSearchState state;
  final String query;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search Open Library'));
    }
    if (state.isEmpty) {
      return Center(child: Text('No results for "$query"'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${state.numFound} results',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            itemCount: state.books.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index < state.books.length) {
                return BookTile(book: state.books[index]);
              }
              return LoadMoreFooter(state: state);
            },
          ),
        ),
      ],
    );
  }
}
