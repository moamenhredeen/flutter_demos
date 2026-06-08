/// Cover/photo image sizes supported by the Open Library Covers API.
enum OpenLibraryImageSize {
  small('S'),
  medium('M'),
  large('L');

  const OpenLibraryImageSize(this.code);

  final String code;
}

/// Builds URLs for the Open Library Covers API (`covers.openlibrary.org`).
///
/// These are plain image URLs — pass them to `Image.network` / `NetworkImage`.
abstract final class OpenLibraryCovers {
  static const _base = 'https://covers.openlibrary.org';

  /// Cover image URL by cover id (the `cover_i` / `covers` field).
  static String byId(int coverId, {OpenLibraryImageSize size = OpenLibraryImageSize.medium}) {
    return '$_base/b/id/$coverId-${size.code}.jpg';
  }

  /// Cover image URL by ISBN.
  static String byIsbn(String isbn, {OpenLibraryImageSize size = OpenLibraryImageSize.medium}) {
    return '$_base/b/isbn/$isbn-${size.code}.jpg';
  }

  /// Author photo URL by photo id (the `photos` field).
  static String authorPhoto(int photoId, {OpenLibraryImageSize size = OpenLibraryImageSize.medium}) {
    return '$_base/a/id/$photoId-${size.code}.jpg';
  }
}
