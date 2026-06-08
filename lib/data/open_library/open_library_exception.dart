import 'package:dio/dio.dart';

/// Error thrown by [OpenLibraryRepository] for failed requests.
///
/// Cancellations are *not* wrapped in this type — they are rethrown as the
/// original [DioException] with [DioException.type] of
/// [DioExceptionType.cancel] so callers can distinguish "user cancelled" from
/// "request failed". Use [isCancellation] to check a caught error.
class OpenLibraryException implements Exception {
  const OpenLibraryException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  /// True if [error] represents a cancelled request (via `CancelToken`).
  static bool isCancellation(Object? error) =>
      error is DioException && error.type == DioExceptionType.cancel;

  @override
  String toString() => 'OpenLibraryException: $message'
      '${statusCode != null ? ' (status $statusCode)' : ''}';
}
