/// A single search result from the Open Library Search API (`/search.json`).
///
/// Only the commonly useful fields are modelled. The raw API returns many more
/// fields; unknown ones are ignored during parsing.
class OpenLibraryDoc {
  const OpenLibraryDoc({
    required this.key,
    required this.title,
    this.authorNames = const [],
    this.firstPublishYear,
    this.coverId,
    this.editionCount,
    this.isbns = const [],
    this.languages = const [],
  });

  /// Work key, e.g. `/works/OL45883W`.
  final String key;

  final String title;

  final List<String> authorNames;

  final int? firstPublishYear;

  /// Cover image id, used to build a cover URL. See [OpenLibraryDoc.coverUrl].
  final int? coverId;

  final int? editionCount;

  final List<String> isbns;

  final List<String> languages;

  /// The work id without the `/works/` prefix, e.g. `OL45883W`.
  String get workId => key.startsWith('/works/') ? key.substring(7) : key;

  factory OpenLibraryDoc.fromJson(Map<String, dynamic> json) {
    return OpenLibraryDoc(
      key: json['key'] as String,
      title: json['title'] as String? ?? '',
      authorNames: _stringList(json['author_name']),
      firstPublishYear: (json['first_publish_year'] as num?)?.toInt(),
      coverId: (json['cover_i'] as num?)?.toInt(),
      editionCount: (json['edition_count'] as num?)?.toInt(),
      isbns: _stringList(json['isbn']),
      languages: _stringList(json['language']),
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return const [];
}
