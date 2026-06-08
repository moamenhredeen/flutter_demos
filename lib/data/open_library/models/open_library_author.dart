/// Details of an author from the Open Library Authors API
/// (`/authors/{id}.json`).
class OpenLibraryAuthor {
  const OpenLibraryAuthor({
    required this.key,
    required this.name,
    this.bio,
    this.birthDate,
    this.deathDate,
    this.photoIds = const [],
  });

  /// Author key, e.g. `/authors/OL23919A`.
  final String key;

  final String name;

  /// Plain-text biography. Flattened from string or `{type, value}` object.
  final String? bio;

  final String? birthDate;

  final String? deathDate;

  final List<int> photoIds;

  String get authorId => key.startsWith('/authors/') ? key.substring(9) : key;

  factory OpenLibraryAuthor.fromJson(Map<String, dynamic> json) {
    return OpenLibraryAuthor(
      key: json['key'] as String,
      name: json['name'] as String? ?? '',
      bio: _flatten(json['bio']),
      birthDate: json['birth_date'] as String?,
      deathDate: json['death_date'] as String?,
      photoIds: _intList(json['photos']),
    );
  }
}

String? _flatten(dynamic value) {
  if (value is String) return value;
  if (value is Map && value['value'] is String) {
    return value['value'] as String;
  }
  return null;
}

List<int> _intList(dynamic value) {
  if (value is List) {
    return value.whereType<num>().map((e) => e.toInt()).toList(growable: false);
  }
  return const [];
}
