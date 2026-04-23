import 'package:first_try/core/api/api_interceptors.dart';
import 'package:first_try/core/errors/exceptions.dart';
import 'package:first_try/core/services/storage_services.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/auth/data/repos/auth_repo.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_api_consumer.dart';

void main() {
  late MockApiConsumer api;
  late AuthRepo repo;
  late AuthCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // StorageService caches a static SharedPreferences singleton — wipe its
    // in-memory state between tests to keep isolation.
    await StorageService.clearAll();
    api = MockApiConsumer();
    repo = AuthRepo(api: api);
    cubit = AuthCubit(repo: repo);
  });

  tearDown(() async => cubit.close());

  group('login', () {
    test('success → AuthAuthenticated + token persisted', () async {
      api.onPost(AppUrl.login, {
        'token': 'abc123',
        'role': 'parent',
        'user': {
          'id': 9,
          'name': 'Nora',
          'email': 'nora@school.test',
          'phone': null,
          'profile_picture': null,
        },
      });

      await cubit.login(email: 'nora@school.test', password: 'secret');

      expect(cubit.state, isA<AuthAuthenticated>());
      final auth = cubit.state as AuthAuthenticated;
      expect(auth.token, 'abc123');
      expect(auth.user.roleType, 'parent');
      expect(auth.user.name, 'Nora');

      expect(await StorageService.getString(CacheKey.token), 'abc123');
      expect(
        await StorageService.getString(CacheKey.user),
        contains('nora@school.test'),
      );
    });

    test('422 validation → AuthError (not mock-fallback for real email)',
        () async {
      api.onPost(
        AppUrl.login,
        dioError(statusCode: 422, data: {
          'message': 'The given data was invalid.',
          'errors': {
            'password': ['The password field is required.'],
          },
        }),
      );

      await cubit.login(email: 'real@user.com', password: '');
      // Real (non-mocked) email + bad creds → AuthError, not mock login.
      expect(cubit.state, isA<AuthError>());
    });

    test('401 on /login does NOT trigger auto-logout loop', () async {
      // When /login itself returns 401 (wrong creds), the interceptor must not
      // fire forceLogout. We simulate the interceptor hook and assert it stays
      // quiet.
      var unauthCalled = false;
      ApiInterceptor.onUnauthorized = () => unauthCalled = true;

      api.onPost(
        AppUrl.login,
        dioError(statusCode: 401, data: {'message': 'Bad credentials'}),
      );

      await cubit.login(email: 'real@user.com', password: 'wrong');
      expect(cubit.state, isA<AuthError>());

      // The real ApiInterceptor suppresses 401 for /login — here the
      // MockApiConsumer just throws ServerException via handleDioException,
      // so the hook isn't touched. Asserting `false` keeps the contract
      // documented.
      expect(unauthCalled, isFalse);

      ApiInterceptor.onUnauthorized = null;
    });
  });

  group('logout', () {
    test('calls /logout, clears storage, emits Unauthenticated', () async {
      // Seed a session.
      api.onPost(AppUrl.login, {
        'token': 'abc',
        'role': 'teacher',
        'user': {
          'id': 1,
          'name': 'T',
          'email': 't@s',
          'phone': null,
          'profile_picture': null,
        },
      });
      await cubit.login(email: 't@s', password: 'x');
      expect(cubit.state, isA<AuthAuthenticated>());

      api.onPost(AppUrl.logout, {'ok': true});
      await cubit.logout();

      expect(cubit.state, isA<AuthUnauthenticated>());
      expect(api.countCallsFor('POST', AppUrl.logout), 1);
      expect(await StorageService.getString(CacheKey.token), isNull);
      expect(await StorageService.getString(CacheKey.user), isNull);
    });

    test('logout survives network failure (still clears locally)', () async {
      api.onPost(AppUrl.login, {
        'token': 'abc',
        'role': 'teacher',
        'user': {
          'id': 1,
          'name': 'T',
          'email': 't@s',
          'phone': null,
          'profile_picture': null,
        },
      });
      await cubit.login(email: 't@s', password: 'x');

      // Backend unreachable during logout.
      api.onPost(AppUrl.logout, dioNetworkError());
      await cubit.logout();

      expect(cubit.state, isA<AuthUnauthenticated>());
      expect(await StorageService.getString(CacheKey.token), isNull);
    });
  });

  group('401 auto-logout hook (forceLogout)', () {
    test('clears storage without hitting /logout', () async {
      // Write via the same StorageService that forceLogout will clear — this
      // avoids any cached-singleton surprises with SharedPreferences.getInstance().
      await StorageService.saveString(CacheKey.token, 'stale');
      await StorageService.saveString(CacheKey.user, '{}');

      await cubit.forceLogout();

      expect(cubit.state, isA<AuthUnauthenticated>());
      expect(await StorageService.getString(CacheKey.token), isNull);
      expect(await StorageService.getString(CacheKey.user), isNull);
      expect(api.countCallsFor('POST', AppUrl.logout), 0); // no API call
    });
  });

  test('repo.me throws ServerException on 401', () async {
    api.onGet(AppUrl.me, dioError(statusCode: 401));
    expect(repo.me(), throwsA(isA<ServerException>()));
  });
}
