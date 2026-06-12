import 'package:dio/dio.dart';

class GtdException implements Exception {
  const GtdException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  static bool isCancellation(Object? error) =>
      error is DioException && error.type == DioExceptionType.cancel;

  @override
  String toString() => statusCode != null
      ? 'GtdException($statusCode): $message'
      : 'GtdException: $message';
}
