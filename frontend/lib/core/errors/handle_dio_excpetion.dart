import 'package:dio/dio.dart';
import 'package:first_try/core/errors/error_model.dart';
import 'package:first_try/core/errors/exceptions.dart';
import 'package:first_try/core/errors/failure_mapper.dart';

/// Legacy entry point — kept for backwards compatibility with existing
/// throwing-style repos. Internally delegates to [mapDioExceptionToFailure]
/// so the error strings / status-code behavior is consistent everywhere.
///
/// New code should prefer the Result<T> + Failure pattern directly.
void handleDioException(DioException e) {
  final failure = mapDioExceptionToFailure(e);
  throw ServerException(
    errorModel: ErrorModel(
      message: failure.message,
      status: e.response?.statusCode?.toString(),
    ),
  );
}
