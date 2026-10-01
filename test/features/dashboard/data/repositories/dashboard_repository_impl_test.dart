import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:fresh_keep_admin/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/product_type_count.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/usecases/get_product_type_counts_usecase.dart';

import '../../../../fakes/fake_http_adapter.dart';

DashboardRepositoryImpl _repository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8082'))
    ..httpClientAdapter = adapter;
  return DashboardRepositoryImpl(
    remoteDataSource: DashboardRemoteDataSource(dio),
  );
}

/// Models extend the entities, and Equatable compares runtimeType, so
/// repository results are compared by props.
List<List<Object?>> _props(Iterable<dynamic> values) => [
  for (final value in values) (value as dynamic).props as List<Object?>,
];

void main() {
  test('product types parse {productType, productCount}', () async {
    final adapter = JsonResponseAdapter(
      statusCode: 200,
      body: [
        {'productType': 'DAIRY', 'productCount': 12},
      ],
    );

    final result = await _repository(adapter).getProductTypeCounts();

    expect(adapter.requests.single.path, '/api/v1/admin/product-types');
    expect(_props(result.getRight().toNullable()!), [
      const ProductTypeCount(productType: 'DAIRY', count: 12).props,
    ]);
  });

  test('an unreadable body maps to ServerFailure', () async {
    final result = await _repository(
      JsonResponseAdapter(statusCode: 200, body: {'not': 'a list'}),
    ).getProductTypeCounts();

    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });

  group('use case', () {
    test('product types are sorted by count desc, then label', () async {
      final result = await GetProductTypeCountsUseCase(
        _repository(
          JsonResponseAdapter(
            statusCode: 200,
            body: [
              {'productType': 'MEAT', 'productCount': 2},
              {'productType': 'DAIRY', 'productCount': 9},
              {'productType': 'BAKERY', 'productCount': 2},
            ],
          ),
        ),
      )();

      expect(result.getRight().toNullable()!.map((c) => c.productType), [
        'DAIRY',
        'BAKERY',
        'MEAT',
      ]);
    });
  });
}
