import 'package:flutter/material.dart';
import 'package:flutter_demos/data/open_library/open_library.dart';

/// One row in the search results list.
class BookTile extends StatelessWidget {
  const BookTile({super.key, required this.book});

  final OpenLibraryDoc book;

  @override
  Widget build(BuildContext context) {
    final cover = book.coverId;
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: cover != null
            ? Image.network(
                OpenLibraryCovers.byId(cover, size: OpenLibraryImageSize.small),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.book_outlined),
              )
            : const Icon(Icons.book_outlined),
      ),
      title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (book.authorNames.isNotEmpty) book.authorNames.first,
          if (book.firstPublishYear != null) '${book.firstPublishYear}',
        ].join(' · '),
      ),
    );
  }
}
