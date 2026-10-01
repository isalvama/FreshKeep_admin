import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/dio_failure_mapper.dart';
import 'package:fresh_keep_admin/features/users/data/datasources/users_remote_datasource.dart';
import 'package:fresh_keep_admin/features/users/data/repositories/users_repository_impl.dart';
import 'package:fresh_keep_admin/features/users/domain/entities/registered_user.dart';
import 'package:fresh_keep_admin/features/users/domain/entities/user_details.dart';
import 'package:fresh_keep_admin/features/users/domain/entities/users_page.dart';
import 'package:fresh_keep_admin/features/users/domain/usecases/get_user_details_usecase.dart';
import 'package:fresh_keep_admin/features/users/domain/usecases/get_users_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/date_range.dart';

import '../../../../fakes/fake_http_adapter.dart';

final _range = DateRange(
  from: DateTime.utc(2026, 9, 2),
  to: DateTime.utc(2026, 10, 1),
);

UsersRepositoryImpl _repository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8082'))
    ..httpClientAdapter = adapter;
  return UsersRepositoryImpl(remoteDataSource: UsersRemoteDataSource(dio));
}

Map<String, dynamic> _userJson({
  String id = 'u-1',
  String? username = 'fresh-user',
  String? lastLoggedAt = '2026-09-20T08:30:00Z',
}) => {
  'id': id,
  'email': '$id@example.com',
  'username': username,
  'registeredAt': '2026-09-14T12:32:05.123456Z',
  'lastLoggedAt': lastLoggedAt,
};

Map<String, dynamic> _pageJson({
  List<Map<String, dynamic>>? content,
  int page = 1,
  int totalElements = 1,
  int totalPages = 1,
}) => {
  'content': content ?? [_userJson()],
  'page': page,
  'size': 30,
  'totalElements': totalElements,
  'totalPages': totalPages,
};

Map<String, dynamic> _detailsJson({String? storeName = 'SuperMart'}) => {
  ..._userJson(),
  'roles': ['USER', 'ADMIN'],
  'spaces': [
    {'id': 's-1', 'name': 'Kitchen'},
  ],
  'receipts': [
    {
      'id': 'r-1',
      'createdAt': '2026-09-15T10:00:00Z',
      'purchaseDate': '2026-09-14',
      'storeName': storeName,
    },
  ],
};

UsersPage _page({
  int page = 1,
  int users = 30,
  int total = 214,
  int pages = 8,
}) => UsersPage(
  users: [
    for (var i = 0; i < users; i++)
      RegisteredUser(
        id: '$i',
        email: '$i@x.com',
        username: null,
        registeredAt: DateTime.utc(2026),
        lastLoggedAt: null,
      ),
  ],
  page: page,
  size: 30,
  totalElements: total,
  totalPages: pages,
);

void main() {
  group('getUsers', () {
    test('GETs /api/v1/admin/users with from, to, page and size=30', () async {
      final adapter = JsonResponseAdapter(statusCode: 200, body: _pageJson());

      await _repository(adapter).getUsers(_range, page: 2);

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/v1/admin/users');
      expect(request.queryParameters, {
        'from': '2026-09-02',
        'to': '2026-10-01',
        'page': 2,
        'size': 30,
      });
    });

    test('parses the page and its users, with times as UTC', () async {
      final result = await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: _pageJson(page: 2, totalElements: 214, totalPages: 8),
        ),
      ).getUsers(_range, page: 2);

      final page = result.getRight().toNullable()!;
      expect(page.page, 2);
      expect(page.size, 30);
      expect(page.totalElements, 214);
      expect(page.totalPages, 8);
      final user = page.users.single;
      expect(user.id, 'u-1');
      expect(user.email, 'u-1@example.com');
      expect(user.username, 'fresh-user');
      expect(user.registeredAt, DateTime.utc(2026, 9, 14, 12, 32, 5, 123, 456));
      expect(user.registeredAt.isUtc, isTrue);
      expect(user.lastLoggedAt, DateTime.utc(2026, 9, 20, 8, 30));
    });

    test('accepts a null username and a null lastLoggedAt', () async {
      final result = await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: _pageJson(
            content: [_userJson(username: null, lastLoggedAt: null)],
          ),
        ),
      ).getUsers(_range, page: 1);

      final user = result.getRight().toNullable()!.users.single;
      expect(user.username, isNull);
      expect(user.lastLoggedAt, isNull);
    });

    test('the use case passes range and page through', () async {
      final adapter = JsonResponseAdapter(statusCode: 200, body: _pageJson());

      await GetUsersUseCase(_repository(adapter))(_range, page: 3);

      expect(adapter.requests.single.queryParameters['page'], 3);
    });
  });

  group('UsersPage positions', () {
    test('page 2 of 214 is 31–60', () {
      final page = _page(page: 2);

      expect(page.firstIndex, 31);
      expect(page.lastIndex, 60);
      expect(page.hasPrevious, isTrue);
      expect(page.hasNext, isTrue);
    });

    test('the last, partial page is 211–214', () {
      final page = _page(page: 8, users: 4);

      expect(page.firstIndex, 211);
      expect(page.lastIndex, 214);
      expect(page.hasNext, isFalse);
    });

    test('page 1 has no previous', () {
      expect(_page(page: 1).hasPrevious, isFalse);
    });

    test('an empty page is 0–0', () {
      final page = _page(page: 9, users: 0, total: 0, pages: 0);

      expect(page.firstIndex, 0);
      expect(page.lastIndex, 0);
      expect(page.hasNext, isFalse);
    });
  });

  group('getUser', () {
    test('GETs /api/v1/admin/users/{id}', () async {
      final adapter = JsonResponseAdapter(
        statusCode: 200,
        body: _detailsJson(),
      );

      await _repository(adapter).getUser('u-1');

      expect(adapter.requests.single.path, '/api/v1/admin/users/u-1');
    });

    test('encodes the id so it stays one path segment', () async {
      final adapter = JsonResponseAdapter(
        statusCode: 200,
        body: _detailsJson(),
      );

      await _repository(adapter).getUser('../products');

      expect(adapter.requests.single.path, '/api/v1/admin/users/..%2Fproducts');
    });

    test('parses profile, roles, spaces and receipts', () async {
      final result = await GetUserDetailsUseCase(
        _repository(JsonResponseAdapter(statusCode: 200, body: _detailsJson())),
      )('u-1');

      final user = result.getRight().toNullable()!;
      expect(user.email, 'u-1@example.com');
      expect(user.roles, ['USER', 'ADMIN']);
      expect(user.spaces, [const UserSpace(id: 's-1', name: 'Kitchen')]);
      expect(user.receipts, [
        UserReceipt(
          id: 'r-1',
          createdAt: DateTime.utc(2026, 9, 15, 10),
          purchaseDate: DateTime.utc(2026, 9, 14),
          storeName: 'SuperMart',
        ),
      ]);
    });

    test('accepts a receipt without a store name', () async {
      final result = await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: _detailsJson(storeName: null),
        ),
      ).getUser('u-1');

      expect(result.getRight().toNullable()!.receipts.single.storeName, isNull);
    });
  });

  group('failures', () {
    test(
      'a missing user (400) is a ValidationFailure with the detail',
      () async {
        final result = await _repository(
          JsonResponseAdapter(
            statusCode: 400,
            body: {'detail': 'User with id u-9 does not exist.'},
          ),
        ).getUser('u-9');

        final failure = result.getLeft().toNullable()!;
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'User with id u-9 does not exist.');
      },
    );

    test('401, 500 and network errors map through the shared mapper', () async {
      Future<AdminFailure> fail(HttpClientAdapter a) async =>
          (await _repository(
            a,
          ).getUsers(_range, page: 1)).getLeft().toNullable()!;

      expect(
        await fail(JsonResponseAdapter(statusCode: 401)),
        isA<UnauthorizedFailure>(),
      );
      expect(
        await fail(JsonResponseAdapter(statusCode: 500)),
        isA<ServerFailure>(),
      );
      expect(await fail(ConnectionErrorAdapter()), isA<NetworkFailure>());
    });

    test('an unreadable body is a ServerFailure', () async {
      for (final body in <Object>[
        [],
        _pageJson(content: [_userJson()..remove('registeredAt')]),
        _pageJson(content: [_userJson()..['registeredAt'] = 'yesterday']),
        _pageJson()..remove('totalPages'),
      ]) {
        final failure = (await _repository(
          JsonResponseAdapter(statusCode: 200, body: body),
        ).getUsers(_range, page: 1)).getLeft().toNullable();

        expect(failure, isA<ServerFailure>(), reason: '$body');
        expect(failure!.message, kServerMessage);
      }

      final details = (await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: _detailsJson()
            ..['receipts'] = [
              {
                'id': 'r',
                'createdAt': '2026-09-15T10:00:00Z',
                'purchaseDate': '14/09/2026',
              },
            ],
        ),
      ).getUser('u-1')).getLeft().toNullable();
      expect(details, isA<ServerFailure>());
    });
  });
}
