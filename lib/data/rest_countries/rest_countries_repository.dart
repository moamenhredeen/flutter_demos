import 'package:dio/dio.dart';

import 'models/country.dart';
import 'rest_countries_exception.dart';

/// Repository over the REST Countries API (https://restcountries.com/v3.1).
///
/// ## Cancellation
///
/// Every method takes an optional [CancelToken]; call `token.cancel()` to abort
/// the in-flight request (e.g. cancel a stale name search as the user types).
///
/// ```dart
/// final token = CancelToken();
/// final hits = await repo.byName('germ', cancelToken: token);
/// // query changed:
/// token.cancel();
/// ```
///
/// A cancelled request throws the original [DioException] (type
/// [DioExceptionType.cancel]); check via [RestCountriesException.isCancellation].
/// Other failures throw [RestCountriesException].
///
/// ## 404 handling
///
/// REST Countries answers no-match lookups with HTTP 404. List-returning search
/// methods ([all], [byName], [byCodes], [byRegion]) treat 404 as an empty
/// result and return `[]`. The single-result [byCode] throws a
/// [RestCountriesException] (check [RestCountriesException.notFound]).
class RestCountriesRepository {
  RestCountriesRepository(this._dio);

  final Dio _dio;

  /// Default field set used to keep payloads small. `/all` *requires* a field
  /// filter, so a sensible default is always sent.
  static const defaultFields = [
    'name',
    'cca2',
    'cca3',
    'capital',
    'region',
    'subregion',
    'population',
    'area',
    'flags',
    'latlng',
    'currencies',
    'languages',
    'timezones',
    'borders',
    'maps',
  ];

  /// All countries. Maps to `GET /all`.
  Future<List<Country>> all({
    List<String> fields = defaultFields,
    CancelToken? cancelToken,
  }) {
    return _getList(
      '/all',
      queryParameters: {'fields': fields.join(',')},
      cancelToken: cancelToken,
    );
  }

  /// Search by (partial) country name. Maps to `GET /name/{name}`.
  ///
  /// Set [fullText] to match the full name only.
  Future<List<Country>> byName(
    String name, {
    bool fullText = false,
    List<String> fields = defaultFields,
    CancelToken? cancelToken,
  }) {
    return _getList(
      '/name/${Uri.encodeComponent(name)}',
      queryParameters: {
        'fields': fields.join(','),
        if (fullText) 'fullText': true,
      },
      cancelToken: cancelToken,
    );
  }

  /// Look up one country by alpha-2 or alpha-3 code. Maps to `GET /alpha/{code}`.
  Future<Country> byCode(
    String code, {
    List<String> fields = defaultFields,
    CancelToken? cancelToken,
  }) async {
    final data = await _get(
      '/alpha/${Uri.encodeComponent(code)}',
      queryParameters: {'fields': fields.join(',')},
      cancelToken: cancelToken,
    );
    // /alpha/{code} returns either an object or a single-element array.
    final json = data is List ? (data.isNotEmpty ? data.first : null) : data;
    if (json is! Map) {
      throw RestCountriesException('No country for code "$code"',
          statusCode: 404);
    }
    return Country.fromJson(json.cast<String, dynamic>());
  }

  /// Look up several countries by code. Maps to `GET /alpha?codes=...`.
  ///
  /// Handy for resolving [Country.borders].
  Future<List<Country>> byCodes(
    List<String> codes, {
    List<String> fields = defaultFields,
    CancelToken? cancelToken,
  }) {
    if (codes.isEmpty) return Future.value(const []);
    return _getList(
      '/alpha',
      queryParameters: {
        'codes': codes.join(','),
        'fields': fields.join(','),
      },
      cancelToken: cancelToken,
    );
  }

  /// All countries in a region (e.g. `Europe`). Maps to `GET /region/{region}`.
  Future<List<Country>> byRegion(
    String region, {
    List<String> fields = defaultFields,
    CancelToken? cancelToken,
  }) {
    return _getList(
      '/region/${Uri.encodeComponent(region)}',
      queryParameters: {'fields': fields.join(',')},
      cancelToken: cancelToken,
    );
  }

  // --- internals -----------------------------------------------------------

  Future<List<Country>> _getList(
    String path, {
    Map<String, dynamic>? queryParameters,
    required CancelToken? cancelToken,
  }) async {
    try {
      final data = await _get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => Country.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    } on RestCountriesException catch (e) {
      // No match -> empty result for list searches.
      if (e.notFound) return const [];
      rethrow;
    }
  }

  Future<dynamic> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
    required CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      throw RestCountriesException(
        e.message ?? 'Request to $path failed',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    }
  }
}
