import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';

/// Retries transient failures with exponential backoff + jitter.
///
/// Retries on:
///   • DioExceptionType.connectionError / connectionTimeout / receiveTimeout /
///     sendTimeout
///   • 5xx responses (server-side transient errors)
///
/// Does NOT retry on:
///   • 4xx (client errors, including 401 — handled by ApiInterceptor)
///   • Cancelled requests
///   • Non-idempotent methods (POST/PATCH/PUT) unless the caller opts in via
///     `options.extra['retry'] = true` — avoids double-submits for things like
///     creating a complaint or posting a stop event.
///
/// Token refresh: intentionally NOT implemented. The backend uses Laravel
/// Sanctum with opaque bearer tokens and no refresh endpoint — a 401 is
/// terminal and must force a re-login. See `ApiInterceptor.onError`.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    final attempt = (req.extra['_retryAttempt'] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries || !_isRetryable(req)) {
      return handler.next(err);
    }

    final next = attempt + 1;
    final delay = _backoff(next);
    await Future<void>.delayed(delay);

    req.extra['_retryAttempt'] = next;
    try {
      final response = await dio.fetch<dynamic>(req);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        return code >= 500 && code < 600;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  bool _isRetryable(RequestOptions req) {
    final method = req.method.toUpperCase();
    if (method == 'GET' || method == 'HEAD') return true;
    // Opt-in for non-idempotent methods.
    return req.extra['retry'] == true;
  }

  Duration _backoff(int attempt) {
    // 400ms, 800ms, 1600ms ... with ±25% jitter.
    final base = baseDelay.inMilliseconds * math.pow(2, attempt - 1).toInt();
    final jitter = (base * 0.25).toInt();
    final rand = math.Random();
    final delta = rand.nextInt(jitter * 2 + 1) - jitter;
    return Duration(milliseconds: base + delta);
  }
}
