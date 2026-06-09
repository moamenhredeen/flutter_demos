import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_search_providers.dart';
import 'widgets/search_error_view.dart';
import 'widgets/search_results.dart';

/// Infinite-scroll pagination demo backed by the Open Library search API.
///
/// Shows the common Riverpod paging shape: an [AsyncNotifier] owns the
/// accumulated list + paging flags, the first page is the outer [AsyncValue],
/// and a scroll listener drives `loadMore`.
class OpenLibrarySearchScreen extends ConsumerStatefulWidget {
  const OpenLibrarySearchScreen({super.key});

  @override
  ConsumerState<OpenLibrarySearchScreen> createState() => _OpenLibrarySearchScreenState();
}

class _OpenLibrarySearchScreenState extends ConsumerState<OpenLibrarySearchScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Within 300px of the bottom -> pull the next page.
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(bookSearchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final searchAsync = ref.watch(bookSearchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pagination Demo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search books, e.g. "dune"',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
              onSubmitted: (v) =>
                  ref.read(searchQueryProvider.notifier).submit(v),
            ),
          ),
          Expanded(
            child: switch (searchAsync) {
              // First-page load (only when there's nothing to show yet).
              AsyncLoading() when !searchAsync.hasValue =>
                const Center(child: CircularProgressIndicator()),
              AsyncError(:final error) =>
                SearchErrorView(message: error.toString()),
              _ => SearchResults(
                  state: searchAsync.requireValue,
                  query: query,
                  scrollController: _scrollController,
                ),
            },
          ),
        ],
      ),
    );
  }
}
