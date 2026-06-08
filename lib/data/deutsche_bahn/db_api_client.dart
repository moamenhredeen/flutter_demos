import 'package:dio/dio.dart';

/// Thin [Dio] factory for the Deutsche Bahn REST API
/// (db-rest, hosted at v5.db.api.bahn.guru).
///
/// See https://v5.db.api.bahn.guru/api.html. No auth required. Public instance
/// is rate-limited (~100 req/min) — keep traffic modest.
abstract final class DbApiClient {
  static const baseUrl = 'https://v5.db.api.bahn.guru';

  static const userAgent = 'flutter_demos/1.0 (learning project)';

  static Dio create() {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        headers: const {'User-Agent': userAgent},
      ),
    );
  }
}
