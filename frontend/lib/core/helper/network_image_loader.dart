import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:qr_certificate/core/api/api_interceptors.dart';
import 'package:qr_certificate/core/errors/exceptions.dart';
import 'package:qr_certificate/core/errors/error_model.dart';
import 'package:qr_certificate/core/errors/handle_dio_excpetion.dart';

import 'package:qr_certificate/core/utils/app_url.dart';

class NetworkImageLoader {
  static Future<Uint8List> loadBinaryImage(String path) async {
    try {
      final dio = _createDio();

      final response = await dio.get<List<int>>(
        AppUrl.getImageApi(path: path),
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException(
        errorModel:
            ErrorModel(message: 'Error Happend while Loading the Image '),
      );
    }
  }

  static Future<String> loadSvgString(String path) async {
    try {
      final dio = _createDio();

      final response = await dio.get<String>(AppUrl.getImageApi(path: path));
      return response.data!;
    } on DioException catch (e) {
      handleDioException(e);
      rethrow;
    } catch (_) {
      throw ServerException(
        errorModel: ErrorModel(message: 'Failed to Load the "SVG" File'),
      );
    }
  }

  static bool isSvgImage(String path) => path.toLowerCase().endsWith('.svg');

  static Future<Either<Uint8List, String>> loadImage(String url) async {
    if (isSvgImage(url)) {
      final svgdata = await loadSvgString(url);
      return Right(svgdata);
    } else {
      final data = await loadBinaryImage(url);
      return Left(data);
    }
  }

  static Dio _createDio() {
    final dio = Dio();

    dio.options.baseUrl = baseUrlapi;
    dio.options.connectTimeout = const Duration(seconds: 150); // ✅ Safe
    dio.options.receiveTimeout = const Duration(seconds: 150); // ✅ Safe

    // DO NOT set sendTimeout unless you're doing a POST with a body
    // dio.options.sendTimeout = const Duration(seconds: 10); ❌ Not needed on web

    dio.options.followRedirects = false;
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['Accept'] = 'image/*';

    // Interceptors
    dio.interceptors.add(ApiInterceptor());
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
    ));

    return dio;
  }
}
