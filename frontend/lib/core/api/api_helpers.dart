import 'package:dio/dio.dart';
import 'package:first_try/core/errors/failure_mapper.dart';
import 'package:first_try/core/errors/failures.dart';
import 'package:first_try/core/errors/result.dart';

/// Wrap a Dio-returning block so it yields a [Result<T>] instead of throwing.
///
/// Usage inside a repo:
///   Future<Result<User>> loadUser() => safeCall(() async {
///     final data = await api.getApi(AppUrl.me) as Map<String, dynamic>;
///     return User.fromJson(data);
///   });
Future<Result<T>> safeCall<T>(Future<T> Function() block) async {
  try {
    final value = await block();
    return Result.ok(value);
  } on DioException catch (e) {
    return Result.err(mapDioExceptionToFailure(e));
  } catch (e) {
    return Result.err(UnknownFailure(e.toString()));
  }
}

/// Build a Dio FormData for file uploads.
///
///   buildFormData(
///     fields: { 'title': 'My HW' },
///     files:  { 'file': '/path/to/hw.pdf' },
///   )
///
/// Pass the result as `data` to `api.post(..., isFormData: false)` — Dio detects
/// FormData automatically and sends the correct multipart/form-data content type.
Future<FormData> buildFormData({
  Map<String, dynamic> fields = const {},
  Map<String, String> files = const {},
}) async {
  final map = <String, dynamic>{...fields};
  for (final entry in files.entries) {
    map[entry.key] = await MultipartFile.fromFile(
      entry.value,
      filename: entry.value.split(RegExp(r'[\\/]+')).last,
    );
  }
  return FormData.fromMap(map);
}
