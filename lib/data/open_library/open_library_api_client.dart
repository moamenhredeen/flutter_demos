import 'package:dio/dio.dart';

/// Thin [Dio] factory pre-configured for the Open Library API.
///
/// Open Library asks clients to send a descriptive `User-Agent` so they can
/// contact you about heavy usage. Adjust [userAgent] to identify this app.
abstract final class OpenLibraryApiClient {
  static const baseUrl = 'https://openlibrary.org';

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
