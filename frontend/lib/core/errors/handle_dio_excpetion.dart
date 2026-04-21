import 'package:dio/dio.dart';
import 'package:first_try/core/errors/error_model.dart';
import 'package:first_try/core/errors/exceptions.dart';

void handleDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      throw ServerException(
        errorModel: ErrorModel(message: 'Connection timeout. Check internet.'),
      );
    case DioExceptionType.receiveTimeout:
      throw ServerException(
        errorModel: ErrorModel(message: 'Receive timeout. Please try again.'),
      );
    case DioExceptionType.connectionError:
      throw ServerException(
        errorModel: ErrorModel(message: 'No internet connection.'),
      );

    case DioExceptionType.sendTimeout:
      throw ServerException(errorModel: ErrorModel.fromJson(e.response!.data));

    case DioExceptionType.badCertificate:
      throw ServerException(errorModel: ErrorModel.fromJson(e.response!.data));
    case DioExceptionType.cancel:
      throw ServerException(errorModel: ErrorModel.fromJson(e.response!.data));

    case DioExceptionType.unknown:
      throw ServerException(errorModel: ErrorModel.fromJson(e.response!.data));
    case DioExceptionType.badResponse:
      switch (e.response?.statusCode) {
        case 400: //Bad request
          throw ServerException(
              errorModel: ErrorModel.fromJson(e.response!.data));
        case 401: //unauthorized
          throw ServerException(
              errorModel: ErrorModel.fromJson(e.response!.data));
        case 403: //forbidden
          throw ServerException(
              errorModel: ErrorModel.fromJson(e.response!.data));
        case 404: //not found
          throw ServerException(
              errorModel: ErrorModel(message: "Page Not Found"));
        // errorModel: ErrorModel.fromJson(e.response!.data));
        case 409: //cofficient
          throw ServerException(
              errorModel: ErrorModel.fromJson(e.response!.data));
        case 422: //Unprocessable Entity
          throw ServerException(
              errorModel: ErrorModel.fromJson(e.response!.data));
        case 302: //Redirect Entity
          throw ServerException(
              errorModel: ErrorModel(message: e.response!.data));
        case 504: //Server exception
          throw ServerException(
              errorModel: ErrorModel.fromJson(e.response!.data));
        case 500: //valdiation error
          throw ServerException(
              errorModel: ErrorModel.fromJson(e.response!.data));
      }
  }
}
