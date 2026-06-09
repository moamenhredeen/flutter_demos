import 'package:flutter/material.dart';
import 'package:flutter_demos/widgets/search_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'paged_books_providers.dart';
import 'widgets/paged_book_list.dart';

/// Open Library search using the Riverpod pagination case-study pattern:
/// one `autoDispose.family` provider per page, watched lazily by the list.
///
/// Contrast with `open_library_search`, which uses a single accumulating
/// `AsyncNotifier` plus a scroll listener and `loadMore`. Here the list needs
/// neither — scrolling builds more rows, and each row pulls the page it needs.
class OpenLibraryPagedScreen extends ConsumerStatefulWidget {
  const OpenLibraryPagedScreen({super.key});

  @override
  ConsumerState<OpenLibraryPagedScreen> createState() =>
      _OpenLibraryPagedScreenState();
}

class _OpenLibraryPagedScreenState
    extends ConsumerState<OpenLibraryPagedScreen> {
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
        onChanged: (v) => ref.read(pagedQueryProvider.notifier).set(v),
        onSubmitted: (v) => ref.read(pagedQueryProvider.notifier).submit(v),
        onBack: () => context.go('/home'),
      ),
      body: const PagedBookList(),
    );
  }
}
