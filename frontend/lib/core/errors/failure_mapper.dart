import 'package:dio/dio.dart';
import 'package:first_try/core/errors/failures.dart';

/// Central mapping from Dio/HTTP errors to typed domain Failures.
///
/// Laravel error shapes this handles:
///   401 { "message": "Unauthenticated." }
///   403 { "message": "This action is unauthorized." }
///   404 { "message": "Not found" }
///   422 { "message": "The given data was invalid.",
///         "errors": { "email": ["The email has already been taken."] } }
///   5xx { "message": "Server Error" }  (or HTML in production)
Failure mapDioExceptionToFailure(DioException e) {
  // ── Transport-level errors (no HTTP response) ────────────────────────────
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkFailure('Connection timed out. Please try again.');
    case DioExceptionType.connectionError:
      return const NetworkFailure('No internet connection.');
    case DioExceptionType.badCertificate:
      return const NetworkFailure('SSL certificate error.');
    case DioExceptionType.cancel:
      return const UnknownFailure('Request cancelled.');
    case DioExceptionType.unknown:
    case DioExceptionType.badResponse:
      break;
  }

  // ── HTTP response errors ─────────────────────────────────────────────────
  final response  = e.response;
  final status    = response?.statusCode;
  final data      = response?.data;
  final message   = _extractMessage(data);

  switch (status) {
    case 401:
      return AuthFailure(message ?? 'Session expired. Please log in again.');
    case 403:
      return ForbiddenFailure(message ?? 'You do not have permission to do that.');
    case 404:
      return NotFoundFailure(message ?? 'Not found.');
    case 409:
      return ConflictFailure(message ?? 'Conflict.');
    case 422:
      return ValidationFailure(
        message: message ?? 'The given data was invalid.',
        fieldErrors: _extractFieldErrors(data),
      );
    case null:
      return UnknownFailure(message ?? 'Something went wrong.');
    default:
      if (status >= 500 && status < 600) {
        return ServerFailure(
          statusCode: status,
          message: message ?? 'Server error ($status). Please try again.',
        );
      }
      return UnknownFailure(message ?? 'Unexpected error ($status).');
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final m = data['message'];
    if (m is String && m.isNotEmpty) return m;
  }
  return null;
}

Map<String, List<String>> _extractFieldErrors(dynamic data) {
  if (data is! Map<String, dynamic>) return const {};
  final errors = data['errors'];
  if (errors is! Map) return const {};
  final result = <String, List<String>>{};
  errors.forEach((key, value) {
    if (key is String && value is List) {
      result[key] = value.whereType<String>().toList();
    }
  });
  return result;
}
