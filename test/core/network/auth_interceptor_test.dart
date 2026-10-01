import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/constants/storage_keys.dart';
import 'package:fresh_keep_admin/core/network/auth_interceptor.dart';
import 'package:fresh_keep_admin/core/network/session_expired_notifier.dart';

import '../../fakes/fake_http_adapter.dart';
import '../../fakes/in_memory_session_storage.dart';

void main() {
  late InMemorySessionStorage sessionStorage;
  late SessionExpiredNotifier notifier;
  late int notifications;

  setUp(() {
    sessionStorage = InMemorySessionStorage();
    notifier = SessionExpiredNotifier();
    notifications = 0;
    notifier.stream.listen((_) => notifications++);
  });

  tearDown(() => notifier.dispose());

  Dio buildDio(HttpClientAdapter adapter) {
    return Dio(BaseOptions(baseUrl: 'http://localhost:8082'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthInterceptor(
          sessionStorage: sessionStorage,
          sessionExpiredNotifier: notifier,
        ),
      );
  }

  test('attaches the stored token as a Bearer header', () async {
    sessionStorage.write(StorageKeys.jwt, 'jwt-123');
    final adapter = JsonResponseAdapter(statusCode: 200);

    await buildDio(adapter).get('/api/v1/admin/product-types');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer jwt-123');
  });

  test('sends no Authorization header when no token is stored', () async {
    final adapter = JsonResponseAdapter(statusCode: 200);

    await buildDio(adapter).get('/api/v1/admin/product-types');

    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('notifies session expiry on a 401 from an admin endpoint', () async {
    final dio = buildDio(JsonResponseAdapter(statusCode: 401));

    await expectLater(
      dio.get('/api/v1/admin/users'),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 1);
  });

  test('does not notify on a 401 from login (wrong credentials)', () async {
    final dio = buildDio(JsonResponseAdapter(statusCode: 401));

    await expectLater(
      dio.post(kLoginPath, data: {'email': 'a@b.com', 'password': 'x'}),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 0);
  });

  test('does not notify on other errors', () async {
    for (final status in [400, 403, 500]) {
      await expectLater(
        buildDio(
          JsonResponseAdapter(statusCode: status),
        ).get('/api/v1/admin/users'),
        throwsA(isA<DioException>()),
      );
    }
    await expectLater(
      buildDio(ConnectionErrorAdapter()).get('/api/v1/admin/users'),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 0);
  });
}
