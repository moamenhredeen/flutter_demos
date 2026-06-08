import 'package:dio/dio.dart';

import 'models/open_library_author.dart';
import 'models/open_library_search_response.dart';
import 'models/open_library_work.dart';
import 'open_library_exception.dart';

/// Repository over the Open Library REST API.
///
/// See https://openlibrary.org/developers/api.
///
/// ## Cancellation
///
/// Every request method takes an optional [CancelToken]. Pass one in and call
/// `token.cancel()` to abort the in-flight request — typical use is cancelling
/// a stale search when the query changes, or aborting work started by a widget
/// that has since been disposed.
///
/// ```dart
/// final token = CancelToken();
/// final future = repo.search('dune', cancelToken: token);
/// // ...query changed:
/// token.cancel();
/// ```
///
/// A cancelled request throws the original [DioException] (type
/// [DioExceptionType.cancel]); check with [OpenLibraryException.isCancellation].
/// All other failures throw [OpenLibraryException].
class OpenLibraryRepository {
  OpenLibraryRepository(this._dio);

  final Dio _dio;

  /// Search works. Maps to `GET /search.json`.
  ///
  /// [page] is 1-based. [fields] limits the returned doc fields to keep
  /// responses small; pass null to use the API default set.
  Future<OpenLibrarySearchResponse> search(
    String query, {
    int page = 1,
    int limit = 20,
    List<String>? fields = const [
      'key',
      'title',
      'author_name',
      'first_publish_year',
      'cover_i',
      'edition_count',
      'isbn',
      'language',
    ],
    CancelToken? cancelToken,
  }) {
    return _get(
      '/search.json',
      queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
        if (fields != null) 'fields': fields.join(','),
      },
      cancelToken: cancelToken,
      parse: OpenLibrarySearchResponse.fromJson,
    );
  }

  /// Fetch a single work. Maps to `GET /works/{workId}.json`.
  ///
  /// [workId] may be either `OL45883W` or `/works/OL45883W`.
  Future<OpenLibraryWork> getWork(String workId, {CancelToken? cancelToken}) {
    final id = _stripPrefix(workId, '/works/');
    return _get(
      '/works/$id.json',
      cancelToken: cancelToken,
      parse: OpenLibraryWork.fromJson,
    );
  }

  /// Fetch a single author. Maps to `GET /authors/{authorId}.json`.
  ///
  /// [authorId] may be either `OL23919A` or `/authors/OL23919A`.
  Future<OpenLibraryAuthor> getAuthor(
    String authorId, {
    CancelToken? cancelToken,
  }) {
    final id = _stripPrefix(authorId, '/authors/');
    return _get(
      '/authors/$id.json',
      cancelToken: cancelToken,
      parse: OpenLibraryAuthor.fromJson,
    );
  }

  // --- internals -----------------------------------------------------------

  Future<T> _get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required CancelToken? cancelToken,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data == null) {
        throw OpenLibraryException(
          'Empty response body',
          statusCode: response.statusCode,
        );
      }
      return parse(data);
    } on DioException catch (e) {
      // Let cancellations propagate untouched so callers can detect them.
      if (e.type == DioExceptionType.cancel) rethrow;
      throw OpenLibraryException(
        e.message ?? 'Request to $path failed',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    }
  }

  String _stripPrefix(String value, String prefix) =>
      value.startsWith(prefix) ? value.substring(prefix.length) : value;
}
