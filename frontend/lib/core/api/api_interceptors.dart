import 'package:dio/dio.dart';
import 'package:first_try/core/services/storage_services.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.getString('auth_token');
    options.headers.putIfAbsent('Accept', () => 'application/json');

    options.headers['authorization'] = 'Bearer $token';
    // options.headers['authorization'] =
    //     'Bearer 4|Ki6dpW0IrIRsj9tBnFihC9T51AE3aKqdaJA4xn3H6ddc5050';
    super.onRequest(options, handler);
  }
}
