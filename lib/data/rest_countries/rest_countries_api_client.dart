import 'package:dio/dio.dart';

/// Thin [Dio] factory for the REST Countries API.
///
/// See https://restcountries.com. No auth required.
abstract final class RestCountriesApiClient {
  static const baseUrl = 'https://restcountries.com/v3.1';

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
