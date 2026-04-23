import 'package:dio/dio.dart';
import 'package:first_try/core/errors/exceptions.dart';
import 'package:first_try/core/errors/failure_mapper.dart';
import 'package:first_try/core/errors/failures.dart';
import 'package:first_try/core/errors/handle_dio_excpetion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api_consumer.dart';

void main() {
  group('mapDioExceptionToFailure', () {
    test('401 → AuthFailure', () {
      final f = mapDioExceptionToFailure(dioError(
        statusCode: 401,
        data: {'message': 'Unauthenticated.'},
      ));
      expect(f, isA<AuthFailure>());
      expect(f.message, 'Unauthenticated.');
    });

    test('403 → ForbiddenFailure', () {
      final f = mapDioExceptionToFailure(dioError(
        statusCode: 403,
        data: {'message': 'This action is unauthorized.'},
      ));
      expect(f, isA<ForbiddenFailure>());
    });

    test('404 → NotFoundFailure', () {
      final f = mapDioExceptionToFailure(dioError(statusCode: 404));
      expect(f, isA<NotFoundFailure>());
    });

    test('422 → ValidationFailure carries fieldErrors', () {
      final f = mapDioExceptionToFailure(dioError(
        statusCode: 422,
        data: {
          'message': 'The given data was invalid.',
          'errors': {
            'email': ['The email has already been taken.'],
            'password': ['The password must be at least 8 characters.'],
          },
        },
      ));
      expect(f, isA<ValidationFailure>());
      final vf = f as ValidationFailure;
      expect(vf.fieldErrors.keys, containsAll(['email', 'password']));
      expect(vf.firstErrorFor('email'), 'The email has already been taken.');
      expect(vf.firstErrorFor('missing'), isNull);
    });

    test('500 → ServerFailure with status code', () {
      final f = mapDioExceptionToFailure(dioError(statusCode: 500));
      expect(f, isA<ServerFailure>());
      expect((f as ServerFailure).statusCode, 500);
    });

    test('connectionError → NetworkFailure', () {
      final f = mapDioExceptionToFailure(dioNetworkError());
      expect(f, isA<NetworkFailure>());
    });

    test('timeout → NetworkFailure', () {
      final f = mapDioExceptionToFailure(
        dioNetworkError(type: DioExceptionType.connectionTimeout),
      );
      expect(f, isA<NetworkFailure>());
    });
  });

  group('handleDioException (legacy throwing API)', () {
    test('throws ServerException on 422 with error model populated', () {
      expect(
        () => handleDioException(dioError(
          statusCode: 422,
          data: {'message': 'Invalid.'},
        )),
        throwsA(
          isA<ServerException>().having(
            (e) => e.errorModel.status,
            'status',
            '422',
          ),
        ),
      );
    });
  });
}
