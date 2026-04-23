import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures returned from repos/use-cases.
///
/// Use these in Result<T> to express "expected errors" — unlike exceptions,
/// failures are part of the function signature and force the caller to handle them.
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// 401 — token missing / invalid / expired.
/// The ApiInterceptor already force-logs out on 401, but cubits may still
/// receive this if they fire before the interceptor finishes.
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Session expired. Please log in again.'])
      : super(message);
}

/// 403 — authenticated but role/ownership forbids the action.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([String message = 'You do not have permission to do that.'])
      : super(message);
}

/// 404 — resource not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Not found.']) : super(message);
}

/// 422 — Laravel validation error. Carries the full field→messages map so the
/// UI can surface per-field errors on forms.
class ValidationFailure extends Failure {
  /// { field_name: [error1, error2, ...] }
  final Map<String, List<String>> fieldErrors;

  const ValidationFailure({
    required String message,
    this.fieldErrors = const {},
  }) : super(message);

  /// Convenience: first error for a given field, or null.
  String? firstErrorFor(String field) => fieldErrors[field]?.firstOrNull;

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// 409 — conflict (e.g. unique constraint).
class ConflictFailure extends Failure {
  const ConflictFailure([String message = 'Conflict.']) : super(message);
}

/// 5xx — backend crashed / timed out on its end.
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({this.statusCode, String message = 'Server error. Please try again.'})
      : super(message);

  @override
  List<Object?> get props => [message, statusCode];
}

/// No connection / timeout / DNS / SSL.
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection.']) : super(message);
}

/// Fallback for unexpected shapes (malformed JSON, unknown status codes, etc.).
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Something went wrong.']) : super(message);
}
