import 'package:dio/dio.dart';

/// Error thrown by [DbRepository] for failed requests.
///
/// Cancellations are not wrapped: they propagate as the original
/// [DioException] (type [DioExceptionType.cancel]) so callers can tell "user
/// cancelled" from "request failed". Use [isCancellation] on a caught error.
class DbException implements Exception {
  const DbException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  static bool isCancellation(Object? error) =>
      error is DioException && error.type == DioExceptionType.cancel;

  @override
  String toString() => 'DbException: $message'
      '${statusCode != null ? ' (status $statusCode)' : ''}';
}
