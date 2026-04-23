import 'dart:io';

import 'package:dio/dio.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/auth/data/repos/auth_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api_consumer.dart';

void main() {
  late Directory tempDir;
  late File tempFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('upload_test_');
    tempFile = File('${tempDir.path}/avatar.png');
    // Minimal valid-ish byte payload.
    await tempFile.writeAsBytes(List<int>.generate(64, (i) => i));
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('updateProfilePicture POSTs multipart FormData', () async {
    final api = MockApiConsumer();
    final repo = AuthRepo(api: api);

    api.onPost(AppUrl.profilePicture, {
      'profile_picture': 'https://cdn.example/p/42.png',
    });

    final url = await repo.updateProfilePicture(tempFile.path);
    expect(url, 'https://cdn.example/p/42.png');

    final call = api.lastCallFor('POST', AppUrl.profilePicture);
    expect(call, isNotNull);
    expect(call!.data, isA<FormData>());

    final form = call.data as FormData;
    expect(
      form.files.any((f) => f.key == 'profile_picture'),
      isTrue,
      reason: 'profile_picture field must be attached as a file',
    );
    final file = form.files.firstWhere((f) => f.key == 'profile_picture').value;
    expect(file.filename, 'avatar.png');
    expect(file.length, 64);
  });

  test('updateProfilePicture surfaces 422 from backend', () async {
    final api = MockApiConsumer();
    final repo = AuthRepo(api: api);

    api.onPost(
      AppUrl.profilePicture,
      dioError(statusCode: 422, data: {
        'message': 'Invalid image.',
        'errors': {
          'profile_picture': ['The profile_picture must be a JPEG or PNG.'],
        },
      }),
    );

    expect(
      repo.updateProfilePicture(tempFile.path),
      throwsA(isA<Exception>()),
    );
  });

  test('deleteProfilePicture calls DELETE /profile-picture', () async {
    final api = MockApiConsumer();
    final repo = AuthRepo(api: api);
    api.onDelete(AppUrl.profilePicture, {'ok': true});
    await repo.deleteProfilePicture();
    expect(api.countCallsFor('DELETE', AppUrl.profilePicture), 1);
  });
}
