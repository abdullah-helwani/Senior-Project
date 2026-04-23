import 'package:dio/dio.dart';
import 'package:first_try/core/services/storage_services.dart';
import 'package:first_try/core/utils/app_url.dart';

class ApiInterceptor extends Interceptor {
  /// Called when a request returns 401 Unauthorized.
  /// Wired up in main.dart to clear AuthCubit state so go_router redirects to login.
  static void Function()? onUnauthorized;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.getString(CacheKey.token);
    options.headers.putIfAbsent('Accept', () => 'application/json');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Don't auto-logout on a failed /login call — that's just wrong credentials.
      final isLoginCall = err.requestOptions.path.endsWith('/login');
      if (!isLoginCall) {
        await StorageService.remove(CacheKey.token);
        await StorageService.remove(CacheKey.user);
        onUnauthorized?.call();
      }
    }
    super.onError(err, handler);
  }
}
