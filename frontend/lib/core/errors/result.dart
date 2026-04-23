import 'package:first_try/core/errors/failures.dart';

/// Either a successful value or a typed Failure.
///
/// Usage:
///   final result = await repo.loadMarks();
///   result.when(
///     success: (marks) => emit(MarksLoaded(marks)),
///     failure: (f) => emit(MarksError(f.message)),
///   );
sealed class Result<T> {
  const Result();

  /// Success constructor.
  const factory Result.ok(T value) = Success<T>;

  /// Failure constructor.
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk  => this is Success<T>;
  bool get isErr => this is Err<T>;

  /// Get the value or null.
  T? get valueOrNull => switch (this) {
        Success<T>(value: final v) => v,
        Err<T>()                   => null,
      };

  /// Get the failure or null.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Err<T>(failure: final f) => f,
      };

  /// Pattern-match both branches into a single value.
  R fold<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) =>
      switch (this) {
        Success<T>(value: final v)         => success(v),
        Err<T>(failure: final f)           => failure(f),
      };

  /// Side-effect variant of [fold].
  void when({
    required void Function(T value) success,
    required void Function(Failure failure) failure,
  }) {
    switch (this) {
      case Success<T>(value: final v):  success(v);
      case Err<T>(failure: final f):    failure(f);
    }
  }

  /// Transform the success value.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(value: final v) => Result<R>.ok(transform(v)),
        Err<T>(failure: final f)   => Result<R>.err(f),
      };
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
