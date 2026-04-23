import 'package:dio/dio.dart';
import 'package:first_try/core/api/api_consumer.dart';
import 'package:first_try/core/api/api_interceptors.dart';
import 'package:first_try/core/api/retry_interceptor.dart';
import 'package:first_try/core/errors/handle_dio_excpetion.dart';
import 'package:first_try/core/utils/app_url.dart';

class DioConsumer extends ApiConsumer {
  final Dio dio;

  DioConsumer({required this.dio}) {
    dio.options.followRedirects = false;
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.headers['Accept'] = 'application/json';
    dio.interceptors.add(ApiInterceptor());
    dio.interceptors.add(RetryInterceptor(dio: dio));
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
      ),
    );
  }
  @override
  Future delete(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    try {
      final response = await dio.delete(
        url,
        data: isFormData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioException(e);
    }
  }

  @override
  Future getApi(
    String url, {
    data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormUrlEncoded = false,
    bool isFormData = false,
  }) async {
    try {
      final response = await dio.get(
        url,
        data: isFormData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
        options:
            options ??
            (isFormUrlEncoded
                ? Options(contentType: Headers.formUrlEncodedContentType)
                : null),
      );
      return response.data;
    } on DioException catch (e) {
      handleDioException(e);
    }
  }

  @override
  Future patch(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    try {
      final response = await dio.patch(
        url,
        data: isFormData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioException(e);
    }
  }

  @override
  Future post(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    Options? options,
    bool isFormUrlEncoded = false,
  }) async {
    try {
      final response = await dio.post(
        url,
        data: isFormData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
        options:
            options ??
            (isFormUrlEncoded
                ? Options(contentType: Headers.formUrlEncodedContentType)
                : null),
      );
      return response.data;
    } on DioException catch (e) {
      handleDioException(e);
    }
  }

  @override
  Future put(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    try {
      final response = await dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioException(e);
    }
  }
}
