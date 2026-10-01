import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/constants/storage_keys.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/dio_failure_mapper.dart';
import 'package:fresh_keep_admin/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:fresh_keep_admin/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:fresh_keep_admin/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fresh_keep_admin/features/auth/domain/entities/admin.dart';

import '../../../../fakes/fake_http_adapter.dart';
import '../../../../fakes/in_memory_session_storage.dart';
import '../../../../fakes/jwt_factory.dart';

const _email = kTestEmail;
const _password = 'Password1';

Map<String, dynamic> _loginBody(String jwt) => {
  'accountId': kTestAccountId,
  'email': _email,
  'jwtString': jwt,
  'expiresIn': 3600000,
};

void main() {
  late InMemorySessionStorage sessionStorage;

  setUp(() => sessionStorage = InMemorySessionStorage());

  AuthRepositoryImpl buildRepository(HttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8082'))
      ..httpClientAdapter = adapter;
    return AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(dio),
      localDataSource: AuthLocalDataSource(sessionStorage),
    );
  }

  Future<AdminFailure> loginFailure(HttpClientAdapter adapter) async {
    final result = await buildRepository(adapter).login(_email, _password);
    return result.getLeft().toNullable()!;
  }

  group('login', () {
    test('posts the credentials to /api/v1/auth/login', () async {
      final adapter = JsonResponseAdapter(
        statusCode: 200,
        body: _loginBody(buildJwt()),
      );

      await buildRepository(adapter).login(_email, _password);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/v1/auth/login');
      expect(request.data, {'email': _email, 'password': _password});
    });

    test('with an admin token stores it and returns the Admin', () async {
      final jwt = buildJwt();
      final result = await buildRepository(
        JsonResponseAdapter(statusCode: 200, body: _loginBody(jwt)),
      ).login(_email, _password);

      // Compared by props: Equatable also compares runtimeType (AdminModel vs Admin).
      expect(
        result.getRight().toNullable()?.props,
        const Admin(
          accountId: kTestAccountId,
          adminId: kTestAdminId,
          email: _email,
        ).props,
      );
      expect(sessionStorage.values, {StorageKeys.jwt: jwt});
    });

    test(
      'with a USER-only token returns NotAdminFailure and stores nothing',
      () async {
        final jwt = buildJwt(
          roles: ['ROLE_USER'],
          adminId: null,
          userId: 'u-1',
        );

        final failure = await loginFailure(
          JsonResponseAdapter(statusCode: 200, body: _loginBody(jwt)),
        );

        expect(failure, isA<NotAdminFailure>());
        expect(failure.message, kNotAdminMessage);
        expect(sessionStorage.values, isEmpty);
      },
    );

    test(
      'with ROLE_ADMIN but no adminId claim returns ServerFailure and stores nothing',
      () async {
        final failure = await loginFailure(
          JsonResponseAdapter(
            statusCode: 200,
            body: _loginBody(buildJwt(adminId: null)),
          ),
        );

        expect(failure, isA<ServerFailure>());
        expect(sessionStorage.values, isEmpty);
      },
    );

    test('400 returns ValidationFailure with the backend detail', () async {
      final failure = await loginFailure(
        JsonResponseAdapter(
          statusCode: 400,
          body: {'title': 'Validation Error In Body Data', 'detail': 'bad'},
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'bad');
    });

    test('401 returns "Invalid email or password"', () async {
      final failure = await loginFailure(
        JsonResponseAdapter(
          statusCode: 401,
          body: {'detail': 'Invalid Credentials Error: ...'},
        ),
      );

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, kInvalidCredentialsMessage);
    });

    test('403 returns "This account has been disabled."', () async {
      final failure = await loginFailure(JsonResponseAdapter(statusCode: 403));

      expect(failure, isA<ForbiddenFailure>());
      expect(failure.message, kDisabledAccountMessage);
    });

    test('500 returns ServerFailure with generic copy', () async {
      final failure = await loginFailure(
        JsonResponseAdapter(
          statusCode: 500,
          body: {'detail': 'AdminProvisioningPendingException'},
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.message, kServerMessage);
    });

    test('an unreachable server returns NetworkFailure', () async {
      final failure = await loginFailure(ConnectionErrorAdapter());

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, kNetworkMessage);
    });

    test('no failure stores a token', () async {
      for (final status in [400, 401, 403, 500]) {
        await loginFailure(JsonResponseAdapter(statusCode: status));
      }
      await loginFailure(ConnectionErrorAdapter());

      expect(sessionStorage.values, isEmpty);
    });
  });

  group('currentAdmin', () {
    AuthRepositoryImpl repository() =>
        buildRepository(JsonResponseAdapter(statusCode: 500));

    test('returns null when no token is stored', () {
      expect(repository().currentAdmin(), isNull);
    });

    test('returns the Admin for a valid admin token and keeps it', () {
      final jwt = buildJwt();
      sessionStorage.write(StorageKeys.jwt, jwt);

      expect(repository().currentAdmin()?.adminId, kTestAdminId);
      expect(sessionStorage.values, {StorageKeys.jwt: jwt});
    });

    test('returns null and clears an expired token', () {
      sessionStorage.write(
        StorageKeys.jwt,
        buildJwt(expiresIn: const Duration(minutes: -1)),
      );

      expect(repository().currentAdmin(), isNull);
      expect(sessionStorage.values, isEmpty);
    });

    test('returns null and clears a token without ROLE_ADMIN', () {
      sessionStorage.write(
        StorageKeys.jwt,
        buildJwt(roles: ['ROLE_USER'], adminId: null),
      );

      expect(repository().currentAdmin(), isNull);
      expect(sessionStorage.values, isEmpty);
    });

    test('returns null and clears a malformed token', () {
      for (final token in ['garbage', buildJwt(includeExp: false)]) {
        sessionStorage.write(StorageKeys.jwt, token);

        expect(repository().currentAdmin(), isNull, reason: token);
        expect(sessionStorage.values, isEmpty, reason: token);
      }
    });
  });

  test('logout clears the stored token', () {
    sessionStorage.write(StorageKeys.jwt, buildJwt());

    buildRepository(JsonResponseAdapter(statusCode: 500)).logout();

    expect(sessionStorage.values, isEmpty);
  });
}
