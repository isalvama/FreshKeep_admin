import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/dio_failure_mapper.dart';

DioException _withStatus(int status, {Object? body}) {
  final options = RequestOptions(path: '/api/v1/admin/users');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group('mapDioException', () {
    test('400 maps to ValidationFailure with the ProblemDetail detail', () {
      final failure = mapDioException(
        _withStatus(
          400,
          body: {'detail': 'from and to must span between 0 and 90 days'},
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'from and to must span between 0 and 90 days');
    });

    test('400 without a detail falls back to generic copy', () {
      final failure = mapDioException(_withStatus(400));

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, kValidationMessage);
    });

    test('other 4xx statuses map to ValidationFailure', () {
      expect(mapDioException(_withStatus(404)), isA<ValidationFailure>());
      expect(mapDioException(_withStatus(409)), isA<ValidationFailure>());
    });

    test('401 maps to UnauthorizedFailure', () {
      final failure = mapDioException(_withStatus(401));

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, kUnauthorizedMessage);
    });

    test('403 maps to ForbiddenFailure', () {
      final failure = mapDioException(_withStatus(403));

      expect(failure, isA<ForbiddenFailure>());
      expect(failure.message, kForbiddenMessage);
    });

    test(
      '5xx maps to ServerFailure with generic copy, ignoring the detail',
      () {
        for (final status in [500, 502, 503]) {
          final failure = mapDioException(
            _withStatus(
              status,
              body: {'detail': 'AdminPersistenceException: ...'},
            ),
          );

          expect(failure, isA<ServerFailure>());
          expect(failure.message, kServerMessage);
        }
      },
    );

    test('no response maps to NetworkFailure', () {
      final failure = mapDioException(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          reason: 'XMLHttpRequest error',
        ),
      );

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, kNetworkMessage);
    });
  });
}
