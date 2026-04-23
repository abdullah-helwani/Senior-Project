import 'package:dio/dio.dart';
import 'package:first_try/core/api/retry_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// A test adapter that replays a scripted list of responses/errors in order.
class _ScriptedAdapter implements HttpClientAdapter {
  final List<_Step> steps;
  int _i = 0;
  final List<RequestOptions> received = [];

  _ScriptedAdapter(this.steps);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received.add(options);
    if (_i >= steps.length) {
      throw StateError('No more scripted responses');
    }
    final step = steps[_i++];
    if (step.error != null) throw step.error!;
    return ResponseBody.fromString(
      '{}',
      step.status!,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Step {
  final int? status;
  final DioException? error;
  _Step.ok(this.status) : error = null;
  _Step.err(this.error) : status = null;
}

/// Wire a Dio + RetryInterceptor over a scripted adapter. The interceptor's
/// `dio.fetch` uses the same Dio instance so retries replay through the same
/// adapter.
Dio _buildDio(_ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    maxRetries: 2,
    baseDelay: const Duration(milliseconds: 1), // keep tests fast
  ));
  return dio;
}

void main() {
  test('retries on 500 then succeeds on 200', () async {
    final adapter = _ScriptedAdapter([_Step.ok(500), _Step.ok(200)]);
    final dio = _buildDio(adapter);
    final response = await dio.get<dynamic>('/anything');
    expect(response.statusCode, 200);
    expect(adapter.received.length, 2);
  });

  test('retries on connectionError then succeeds', () async {
    final adapter = _ScriptedAdapter([
      _Step.err(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      )),
      _Step.ok(200),
    ]);
    final dio = _buildDio(adapter);
    final response = await dio.get<dynamic>('/x');
    expect(response.statusCode, 200);
    expect(adapter.received.length, 2);
  });

  test('does NOT retry on 4xx', () async {
    final adapter = _ScriptedAdapter([
      _Step.ok(422),
    ]);
    final dio = _buildDio(adapter);
    try {
      await dio.get<dynamic>('/bad');
      fail('expected DioException');
    } on DioException catch (e) {
      expect(e.response?.statusCode, 422);
    }
    expect(adapter.received.length, 1); // no retry
  });

  test('does NOT retry POST by default (non-idempotent)', () async {
    final adapter = _ScriptedAdapter([
      _Step.ok(500),
    ]);
    final dio = _buildDio(adapter);
    try {
      await dio.post<dynamic>('/create', data: {});
      fail('expected DioException');
    } on DioException catch (e) {
      expect(e.response?.statusCode, 500);
    }
    expect(adapter.received.length, 1);
  });

  test('retries POST when caller opts in via extra[retry]=true', () async {
    final adapter = _ScriptedAdapter([
      _Step.ok(500),
      _Step.ok(200),
    ]);
    final dio = _buildDio(adapter);
    final response = await dio.post<dynamic>(
      '/create',
      data: {},
      options: Options(extra: {'retry': true}),
    );
    expect(response.statusCode, 200);
    expect(adapter.received.length, 2);
  });

  test('gives up after maxRetries', () async {
    final adapter = _ScriptedAdapter([
      _Step.ok(500),
      _Step.ok(500),
      _Step.ok(500),
    ]);
    final dio = _buildDio(adapter);
    try {
      await dio.get<dynamic>('/x');
      fail('expected DioException');
    } on DioException catch (_) {}
    expect(adapter.received.length, 3); // initial + 2 retries
  });
}
