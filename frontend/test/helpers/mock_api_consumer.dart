import 'package:dio/dio.dart';
import 'package:first_try/core/api/api_consumer.dart';
import 'package:first_try/core/errors/handle_dio_excpetion.dart';

/// In-memory programmable fake for [ApiConsumer].
///
/// Register responses ahead of time with [onGet] / [onPost] / [onPut] /
/// [onPatch] / [onDelete], then pass the instance to a repo and call it.
///
/// Each call records a [RecordedCall] you can assert on via [calls].
///
/// Features:
///  • Path + method match (exact).
///  • Multi-response queues (first call returns first response, etc.) — useful
///    for testing polling / pagination / retry.
///  • [DioException] responses (simulate 401/422/5xx). They are routed through
///    the real [handleDioException] so the thrown [ServerException] matches
///    what repos actually see in production.
class MockApiConsumer extends ApiConsumer {
  final Map<String, List<Object>> _responses = {};
  final List<RecordedCall> calls = [];

  // ── Registration ──────────────────────────────────────────────────────────

  void onGet(String url, Object response) => _enqueue('GET', url, response);
  void onPost(String url, Object response) => _enqueue('POST', url, response);
  void onPut(String url, Object response) => _enqueue('PUT', url, response);
  void onPatch(String url, Object response) => _enqueue('PATCH', url, response);
  void onDelete(String url, Object response) =>
      _enqueue('DELETE', url, response);

  void _enqueue(String method, String url, Object response) {
    _responses.putIfAbsent(_key(method, url), () => []).add(response);
  }

  String _key(String method, String url) => '$method $url';

  // ── Dispatch ──────────────────────────────────────────────────────────────

  Future<dynamic> _dispatch(
    String method,
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    calls.add(RecordedCall(
      method: method,
      url: url,
      data: data,
      queryParameters: queryParameters,
    ));

    final queue = _responses[_key(method, url)];
    if (queue == null || queue.isEmpty) {
      throw StateError(
        'MockApiConsumer: no response registered for $method $url',
      );
    }

    // If only one response is queued, keep returning it; otherwise pop.
    final response = queue.length == 1 ? queue.first : queue.removeAt(0);

    if (response is DioException) {
      // Routes through real error mapping → throws ServerException like prod.
      handleDioException(response);
    }
    if (response is Exception) throw response;
    return response;
  }

  // ── Helpers for tests ────────────────────────────────────────────────────

  RecordedCall? lastCallFor(String method, String url) {
    for (var i = calls.length - 1; i >= 0; i--) {
      if (calls[i].method == method && calls[i].url == url) return calls[i];
    }
    return null;
  }

  int countCallsFor(String method, String url) =>
      calls.where((c) => c.method == method && c.url == url).length;

  void reset() {
    _responses.clear();
    calls.clear();
  }

  // ── ApiConsumer impl ──────────────────────────────────────────────────────

  @override
  Future getApi(
    String url, {
    data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    bool isFormUrlEncoded = false,
  }) =>
      _dispatch('GET', url, data: data, queryParameters: queryParameters);

  @override
  Future post(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    Options? options,
    bool isFormUrlEncoded = false,
  }) =>
      _dispatch('POST', url, data: data, queryParameters: queryParameters);

  @override
  Future put(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) =>
      _dispatch('PUT', url, data: data, queryParameters: queryParameters);

  @override
  Future patch(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) =>
      _dispatch('PATCH', url, data: data, queryParameters: queryParameters);

  @override
  Future delete(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) =>
      _dispatch('DELETE', url, data: data, queryParameters: queryParameters);
}

class RecordedCall {
  final String method;
  final String url;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;

  RecordedCall({
    required this.method,
    required this.url,
    this.data,
    this.queryParameters,
  });

  @override
  String toString() =>
      'RecordedCall($method $url, data=$data, qp=$queryParameters)';
}

// ── DioException factory helpers ──────────────────────────────────────────

/// Build a DioException that mimics a real Laravel HTTP error response.
DioException dioError({
  required int statusCode,
  Map<String, dynamic>? data,
  String path = '/test',
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

/// Build a transport-level DioException (no HTTP response).
DioException dioNetworkError({
  DioExceptionType type = DioExceptionType.connectionError,
  String path = '/test',
}) {
  final options = RequestOptions(path: path);
  return DioException(requestOptions: options, type: type);
}
