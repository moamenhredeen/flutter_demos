import 'package:dio/dio.dart';

/// Error thrown by [RestCountriesRepository] for failed requests.
///
/// Cancellations are not wrapped: they propagate as the original
/// [DioException] (type [DioExceptionType.cancel]). Use [isCancellation] on a
/// caught error to distinguish "user cancelled" from "request failed".
///
/// Note: REST Countries returns 404 for no-match lookups (e.g. unknown name).
/// Those surface as a [RestCountriesException] with [statusCode] 404 — callers
/// that prefer "empty" over "error" should catch and check [notFound].
class RestCountriesException implements Exception {
  const RestCountriesException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  bool get notFound => statusCode == 404;

  static bool isCancellation(Object? error) =>
      error is DioException && error.type == DioExceptionType.cancel;

  @override
  String toString() => 'RestCountriesException: $message'
      '${statusCode != null ? ' (status $statusCode)' : ''}';
}
