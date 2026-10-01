import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/dio_failure_mapper.dart';
import 'package:fresh_keep_admin/shared/metrics/data/datasources/metrics_remote_datasource.dart';
import 'package:fresh_keep_admin/shared/metrics/data/repositories/metrics_repository_impl.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/daily_count.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/date_range.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_products_added_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_receipts_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_user_registrations_usecase.dart';

import '../../../../fakes/fake_http_adapter.dart';

final _range = DateRange(
  from: DateTime.utc(2026, 9, 1),
  to: DateTime.utc(2026, 9, 3),
);

MetricsRepositoryImpl _repository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8082'))
    ..httpClientAdapter = adapter;
  return MetricsRepositoryImpl(remoteDataSource: MetricsRemoteDataSource(dio));
}

/// Models extend the entities, and Equatable compares runtimeType, so
/// repository results are compared by props.
List<List<Object?>> _props(Iterable<dynamic> values) => [
  for (final value in values) (value as dynamic).props as List<Object?>,
];

DailyCount _count(int day, int count) =>
    DailyCount(date: DateTime.utc(2026, 9, day), count: count);

void main() {
  group('daily metrics', () {
    final endpoints =
        <(String, String, Future<dynamic> Function(MetricsRepositoryImpl))>[
          (
            'registrations',
            '/api/v1/admin/metrics/users/registrations',
            (r) => r.getUserRegistrations(_range),
          ),
          (
            'products',
            '/api/v1/admin/metrics/products',
            (r) => r.getProductsAdded(_range),
          ),
          (
            'receipts',
            '/api/v1/admin/metrics/shopping-receipts',
            (r) => r.getReceipts(_range),
          ),
        ];

    for (final (name, path, call) in endpoints) {
      test('$name GETs $path with from/to as yyyy-MM-dd', () async {
        final adapter = JsonResponseAdapter(statusCode: 200, body: []);

        await call(_repository(adapter));

        final request = adapter.requests.single;
        expect(request.method, 'GET');
        expect(request.path, path);
        expect(request.queryParameters, {
          'from': '2026-09-01',
          'to': '2026-09-03',
        });
      });
    }

    test('products and receipts send creatorId only when given', () async {
      final adapter = JsonResponseAdapter(statusCode: 200, body: []);
      final repository = _repository(adapter);

      await repository.getProductsAdded(_range, creatorId: 'user-1');
      await repository.getReceipts(_range, creatorId: 'user-1');
      await repository.getProductsAdded(_range);
      await repository.getReceipts(_range);
      await repository.getUserRegistrations(_range);

      expect(adapter.requests.map((r) => r.queryParameters['creatorId']), [
        'user-1',
        'user-1',
        null,
        null,
        null,
      ]);
      expect(
        adapter.requests
            .skip(2)
            .every((r) => !r.queryParameters.containsKey('creatorId')),
        isTrue,
      );
    });

    test('use cases pass creatorId through', () async {
      final adapter = JsonResponseAdapter(statusCode: 200, body: []);
      final repository = _repository(adapter);

      await GetProductsAddedUseCase(repository)(_range, creatorId: 'user-2');
      await GetReceiptsUseCase(repository)(_range, creatorId: 'user-2');

      expect(adapter.requests.map((r) => r.queryParameters['creatorId']), [
        'user-2',
        'user-2',
      ]);
    });

    test('parses {date, count}', () async {
      final result = await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: [
            {'date': '2026-09-02', 'count': 4},
          ],
        ),
      ).getUserRegistrations(_range);

      expect(_props(result.getRight().toNullable()!), _props([_count(2, 4)]));
    });

    test('parses the receipts metric count from totalReceipts', () async {
      final result = await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: [
            {'date': '2026-09-01', 'totalReceipts': 3},
          ],
        ),
      ).getReceipts(_range);

      expect(_props(result.getRight().toNullable()!), _props([_count(1, 3)]));
    });
  });

  group('failures', () {
    Future<AdminFailure> failure(HttpClientAdapter adapter) async =>
        (await _repository(
          adapter,
        ).getProductsAdded(_range)).getLeft().toNullable()!;

    test('400 maps to ValidationFailure with the backend detail', () async {
      final f = await failure(
        JsonResponseAdapter(
          statusCode: 400,
          body: {'detail': 'from and to must span between 0 and 100 days'},
        ),
      );

      expect(f, isA<ValidationFailure>());
      expect(f.message, 'from and to must span between 0 and 100 days');
    });

    test('401, 500 and network errors map through the shared mapper', () async {
      expect(
        await failure(JsonResponseAdapter(statusCode: 401)),
        isA<UnauthorizedFailure>(),
      );
      expect(
        await failure(JsonResponseAdapter(statusCode: 500)),
        isA<ServerFailure>(),
      );
      expect(await failure(ConnectionErrorAdapter()), isA<NetworkFailure>());
    });

    test('an unreadable body maps to ServerFailure', () async {
      for (final body in <Object>[
        {'not': 'a list'},
        [
          {'date': 'yesterday', 'count': 1},
        ],
        [
          {'date': '2026-09-01'},
        ],
      ]) {
        final f = await failure(
          JsonResponseAdapter(statusCode: 200, body: body),
        );

        expect(f, isA<ServerFailure>(), reason: '$body');
        expect(f.message, kServerMessage);
      }
    });
  });

  group('use cases', () {
    test('daily use cases zero-fill every day of the range', () async {
      final repository = _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: [
            {'date': '2026-09-02', 'count': 5, 'totalReceipts': 5},
          ],
        ),
      );
      final expected = [_count(1, 0), _count(2, 5), _count(3, 0)];

      for (final call in [
        GetUserRegistrationsUseCase(repository).call,
        GetProductsAddedUseCase(repository).call,
        GetReceiptsUseCase(repository).call,
      ]) {
        expect((await call(_range)).getRight().toNullable(), expected);
      }
    });

    test('daily use cases pass failures through untouched', () async {
      final result = await GetUserRegistrationsUseCase(
        _repository(JsonResponseAdapter(statusCode: 500)),
      )(_range);

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });
}
