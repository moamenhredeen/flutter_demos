/// Details of a single work from the Open Library Works API
/// (`/works/{id}.json`).
class OpenLibraryWork {
  const OpenLibraryWork({
    required this.key,
    required this.title,
    this.description,
    this.subjects = const [],
    this.coverIds = const [],
    this.authorKeys = const [],
  });

  /// Work key, e.g. `/works/OL45883W`.
  final String key;

  final String title;

  /// Plain-text description. The API sometimes returns this as a string and
  /// sometimes as a `{type, value}` object; both are flattened here.
  final String? description;

  final List<String> subjects;

  final List<int> coverIds;

  /// Author keys referenced by this work, e.g. `/authors/OL23919A`.
  final List<String> authorKeys;

  String get workId => key.startsWith('/works/') ? key.substring(7) : key;

  factory OpenLibraryWork.fromJson(Map<String, dynamic> json) {
    return OpenLibraryWork(
      key: json['key'] as String,
      title: json['title'] as String? ?? '',
      description: _flattenDescription(json['description']),
      subjects: _stringList(json['subjects']),
      coverIds: _intList(json['covers']),
      authorKeys: _authorKeys(json['authors']),
    );
  }
}

String? _flattenDescription(dynamic value) {
  if (value is String) return value;
  if (value is Map && value['value'] is String) {
    return value['value'] as String;
  }
  return null;
}

List<String> _authorKeys(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) {
        if (e is Map && e['author'] is Map) {
          return (e['author'] as Map)['key']?.toString();
        }
        return null;
      })
      .whereType<String>()
      .toList(growable: false);
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return const [];
}

List<int> _intList(dynamic value) {
  if (value is List) {
    return value.whereType<num>().map((e) => e.toInt()).toList(growable: false);
  }
  return const [];
}
