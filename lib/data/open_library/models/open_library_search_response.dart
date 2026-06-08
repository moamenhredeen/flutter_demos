import 'open_library_doc.dart';

/// Response shape of the Open Library Search API (`/search.json`).
class OpenLibrarySearchResponse {
  const OpenLibrarySearchResponse({
    required this.numFound,
    required this.start,
    required this.docs,
  });

  /// Total number of matching works (across all pages).
  final int numFound;

  /// Offset of the first doc in [docs] within the full result set.
  final int start;

  final List<OpenLibraryDoc> docs;

  factory OpenLibrarySearchResponse.fromJson(Map<String, dynamic> json) {
    final docsJson = json['docs'] as List? ?? const [];
    return OpenLibrarySearchResponse(
      numFound: (json['numFound'] as num?)?.toInt() ?? 0,
      start: (json['start'] as num?)?.toInt() ?? 0,
      docs: docsJson
          .map((e) => OpenLibraryDoc.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
