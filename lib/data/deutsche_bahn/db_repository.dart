import 'package:dio/dio.dart';

import 'db_exception.dart';
import 'models/db_journey.dart';
import 'models/db_location.dart';
import 'models/db_station_board_entry.dart';

/// Repository over the Deutsche Bahn REST API (db-rest).
///
/// See https://v5.db.api.bahn.guru/api.html.
///
/// ## Cancellation
///
/// Every method takes an optional [CancelToken]; call `token.cancel()` to abort
/// the in-flight request (e.g. cancel a stale station search as the user types,
/// or abort a board refresh when leaving a screen).
///
/// ```dart
/// final token = CancelToken();
/// final hits = await repo.searchLocations('Köln', cancelToken: token);
/// // query changed:
/// token.cancel();
/// ```
///
/// A cancelled request throws the original [DioException] (type
/// [DioExceptionType.cancel]); check via [DbException.isCancellation]. All other
/// failures throw [DbException].
class DbRepository {
  DbRepository(this._dio);

  final Dio _dio;

  /// Search stops, stations, addresses and POIs. Maps to `GET /locations`.
  Future<List<DbLocation>> searchLocations(
    String query, {
    int results = 10,
    bool fuzzy = true,
    bool stops = true,
    bool addresses = true,
    bool poi = true,
    CancelToken? cancelToken,
  }) async {
    final data = await _get(
      '/locations',
      queryParameters: {
        'query': query,
        'results': results,
        'fuzzy': fuzzy,
        'stops': stops,
        'addresses': addresses,
        'poi': poi,
      },
      cancelToken: cancelToken,
    );
    return _mapList(data, DbLocation.fromJson);
  }

  /// Departures board for a stop. Maps to `GET /stops/:id/departures`.
  ///
  /// [when] defaults to now. [duration] is the look-ahead in minutes.
  Future<List<DbDeparture>> departures(
    String stopId, {
    DateTime? when,
    int duration = 60,
    int? results,
    CancelToken? cancelToken,
  }) async {
    final data = await _get(
      '/stops/$stopId/departures',
      queryParameters: {
        'when': ?when?.toIso8601String(),
        'duration': duration,
        'results': ?results,
      },
      cancelToken: cancelToken,
    );
    return _mapList(data, DbStationBoardEntry.fromJson);
  }

  /// Arrivals board for a stop. Maps to `GET /stops/:id/arrivals`.
  Future<List<DbArrival>> arrivals(
    String stopId, {
    DateTime? when,
    int duration = 60,
    int? results,
    CancelToken? cancelToken,
  }) async {
    final data = await _get(
      '/stops/$stopId/arrivals',
      queryParameters: {
        'when': ?when?.toIso8601String(),
        'duration': duration,
        'results': ?results,
      },
      cancelToken: cancelToken,
    );
    return _mapList(data, DbStationBoardEntry.fromJson);
  }

  /// Plan journeys between two stops. Maps to `GET /journeys`.
  ///
  /// [from] and [to] are stop ids (from [searchLocations]). Set [departure] to
  /// search by departure time, or [arrival] to search by arrival time.
  Future<List<DbJourney>> journeys({
    required String from,
    required String to,
    DateTime? departure,
    DateTime? arrival,
    int results = 5,
    bool stopovers = false,
    bool tickets = false,
    CancelToken? cancelToken,
  }) async {
    final data = await _get(
      '/journeys',
      queryParameters: {
        'from': from,
        'to': to,
        if (departure != null) 'departure': departure.toIso8601String(),
        if (arrival != null) 'arrival': arrival.toIso8601String(),
        'results': results,
        'stopovers': stopovers,
        'tickets': tickets,
      },
      cancelToken: cancelToken,
    );
    // `/journeys` returns an object: { journeys: [...] }.
    final journeys = data is Map ? data['journeys'] : data;
    return _mapList(journeys, DbJourney.fromJson);
  }

  // --- internals -----------------------------------------------------------

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
      throw DbException(
        e.message ?? 'Request to $path failed',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    }
  }

  List<T> _mapList<T>(dynamic data, T Function(Map<String, dynamic>) parse) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => parse(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
}
