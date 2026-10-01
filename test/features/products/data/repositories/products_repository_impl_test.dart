import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/dio_failure_mapper.dart';
import 'package:fresh_keep_admin/features/products/data/datasources/products_remote_datasource.dart';
import 'package:fresh_keep_admin/features/products/data/repositories/products_repository_impl.dart';
import 'package:fresh_keep_admin/shared/products/money.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_details.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_filters.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_sort.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_summary.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/receipt_label.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_product_details_usecase.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_products_usecase.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_receipt_label_usecase.dart';

import '../../../../fakes/fake_http_adapter.dart';

ProductsRepositoryImpl _repository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8082'))
    ..httpClientAdapter = adapter;
  return ProductsRepositoryImpl(
    remoteDataSource: ProductsRemoteDataSource(dio),
  );
}

Map<String, dynamic> _summaryJson({
  String id = 'p-1',
  Object? expirationDate = '2026-09-15',
  Object? price = 2.5,
  Object? currency = 'USD',
}) => {
  'id': id,
  'name': 'Milk',
  'expirationDate': expirationDate,
  'actualStorageSpotId': 'spot-1',
  'productType': 'DAIRY',
  'shoppingReceiptId': 'r-1',
  'price': price,
  'currency': currency,
};

Map<String, dynamic> _detailsJson({Object? shoppingReceiptId = 'r-1'}) => {
  'id': 'p-1',
  'name': 'Milk',
  'productType': 'DAIRY',
  'expirationDate': '2026-09-15',
  'actualStorageSpotId': 'spot-1',
  'storageSpotIdType': 'FRIDGE',
  'creatorId': 'u-1',
  'creatorUsername': 'fresh-user',
  'creatorEmail': 'user@example.com',
  'spaceId': 's-1',
  'spaceName': 'Kitchen',
  'storeName': 'SuperMart',
  'purchaseDate': '2026-09-08',
  'createdAt': '2026-09-08T10:00:00Z',
  'shoppingReceiptId': shoppingReceiptId,
  'price': 2.5,
  'currency': 'USD',
};

Map<String, dynamic> _receiptJson({Object? storeName = 'SuperMart'}) => {
  'id': 'r-1',
  'creatorId': 'u-1',
  'storeName': storeName,
  'purchaseDate': '2026-09-08',
  'createdAt': '2026-09-08T10:00:00Z',
  'products': [],
};

void main() {
  group('getProducts', () {
    test('sends sort, page and size=30 when there are no filters', () async {
      final adapter = JsonResponseAdapter(statusCode: 200, body: []);

      await _repository(adapter).getProducts(const ProductFilters(), page: 2);

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/v1/admin/products');
      expect(request.queryParameters, {
        'sort': 'NAME_ASC',
        'page': 2,
        'size': 30,
      });
    });

    test('adds each filter under its backend name', () async {
      final adapter = JsonResponseAdapter(statusCode: 200, body: []);

      await GetProductsUseCase(_repository(adapter))(
        const ProductFilters(
          sort: ProductSort.priceDesc,
          productType: 'DAIRY',
          creatorId: 'u-1',
          receiptId: 'r-1',
        ),
        page: 1,
      );

      expect(adapter.requests.single.queryParameters, {
        'sort': 'PRICE_DESC',
        'page': 1,
        'size': 30,
        'productType': 'DAIRY',
        'creatorId': 'u-1',
        'shoppingReceiptId': 'r-1',
      });
    });

    test('parses the rows into a page of the requested size', () async {
      final result = await _repository(
        JsonResponseAdapter(statusCode: 200, body: [_summaryJson()]),
      ).getProducts(const ProductFilters(), page: 3);

      final page = result.getRight().toNullable()!;
      expect(page.page, 3);
      expect(page.size, 30);
      expect(
        page.products.single.props,
        ProductSummary(
          id: 'p-1',
          name: 'Milk',
          productType: 'DAIRY',
          expirationDate: DateTime.utc(2026, 9, 15),
          price: const Money(amount: 2.5, currency: 'USD'),
        ).props,
      );
    });

    test('reads integer prices too', () async {
      final result = await _repository(
        JsonResponseAdapter(statusCode: 200, body: [_summaryJson(price: 3)]),
      ).getProducts(const ProductFilters(), page: 1);

      expect(
        result.getRight().toNullable()!.products.single.price,
        const Money(amount: 3, currency: 'USD'),
      );
    });

    test('no expiration date, or a price without its currency (or the '
        'reverse), leaves those fields empty', () async {
      final result = await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: [
            _summaryJson(id: 'a', expirationDate: null),
            _summaryJson(id: 'b', currency: null),
            _summaryJson(id: 'c', price: null),
          ],
        ),
      ).getProducts(const ProductFilters(), page: 1);

      final products = result.getRight().toNullable()!.products;
      expect(products[0].expirationDate, isNull);
      expect(products[0].price, isNotNull);
      expect(products[1].price, isNull);
      expect(products[2].price, isNull);
    });
  });

  group('getProduct', () {
    test('GETs /api/v1/admin/products/{id}, encoding the id', () async {
      final adapter = JsonResponseAdapter(
        statusCode: 200,
        body: _detailsJson(),
      );

      await _repository(adapter).getProduct('p-1');
      await _repository(adapter).getProduct('../users');

      expect(adapter.requests.map((r) => r.path), [
        '/api/v1/admin/products/p-1',
        '/api/v1/admin/products/..%2Fusers',
      ]);
    });

    test('parses the product and its origin', () async {
      final result = await GetProductDetailsUseCase(
        _repository(JsonResponseAdapter(statusCode: 200, body: _detailsJson())),
      )('p-1');

      expect(
        result.getRight().toNullable()!.props,
        ProductDetails(
          id: 'p-1',
          name: 'Milk',
          productType: 'DAIRY',
          expirationDate: DateTime.utc(2026, 9, 15),
          storageSpotType: 'FRIDGE',
          price: const Money(amount: 2.5, currency: 'USD'),
          createdAt: DateTime.utc(2026, 9, 8, 10),
          origin: ProductOrigin(
            receiptId: 'r-1',
            creatorId: 'u-1',
            creatorEmail: 'user@example.com',
            creatorUsername: 'fresh-user',
            spaceName: 'Kitchen',
            storeName: 'SuperMart',
            purchaseDate: DateTime.utc(2026, 9, 8),
          ),
        ).props,
      );
    });

    test('a product without a receipt has no origin', () async {
      final json = _detailsJson(shoppingReceiptId: null)
        ..addAll({
          'creatorId': null,
          'creatorUsername': null,
          'creatorEmail': null,
          'spaceId': null,
          'spaceName': null,
          'storeName': null,
          'purchaseDate': null,
          'storageSpotIdType': null,
          'expirationDate': null,
        });

      final product = (await _repository(
        JsonResponseAdapter(statusCode: 200, body: json),
      ).getProduct('p-1')).getRight().toNullable()!;

      expect(product.origin, isNull);
      expect(product.storageSpotType, isNull);
      expect(product.expirationDate, isNull);
    });
  });

  group('chip lookups', () {
    test('getReceiptLabel reads the store and purchase date', () async {
      final adapter = JsonResponseAdapter(
        statusCode: 200,
        body: _receiptJson(),
      );

      final result = await GetReceiptLabelUseCase(_repository(adapter))('r-1');

      expect(
        adapter.requests.single.path,
        '/api/v1/admin/shopping-receipts/r-1',
      );
      expect(
        result.getRight().toNullable()!.props,
        ReceiptLabel(
          storeName: 'SuperMart',
          purchaseDate: DateTime.utc(2026, 9, 8),
        ).props,
      );
    });

    test('a receipt without a store name still has a label', () async {
      final result = await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: _receiptJson(storeName: null),
        ),
      ).getReceiptLabel('r-1');

      expect(result.getRight().toNullable()!.storeName, isNull);
    });

    test('ids are encoded', () async {
      final adapter = JsonResponseAdapter(
        statusCode: 200,
        body: _receiptJson(),
      );

      await _repository(adapter).getReceiptLabel('a/b');

      expect(
        adapter.requests.single.path,
        '/api/v1/admin/shopping-receipts/a%2Fb',
      );
    });
  });

  group('failures', () {
    test(
      'a missing product (400) is a ValidationFailure with the detail',
      () async {
        final result = await _repository(
          JsonResponseAdapter(
            statusCode: 400,
            body: {'detail': 'Product with id p-9 does not exist.'},
          ),
        ).getProduct('p-9');

        final failure = result.getLeft().toNullable()!;
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Product with id p-9 does not exist.');
      },
    );

    test('401, 500 and network errors map through the shared mapper', () async {
      Future<AdminFailure> fail(HttpClientAdapter a) async =>
          (await _repository(a).getProducts(
            const ProductFilters(),
            page: 1,
          )).getLeft().toNullable()!;

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
      Future<AdminFailure?> list(Object body) async => (await _repository(
        JsonResponseAdapter(statusCode: 200, body: body),
      ).getProducts(const ProductFilters(), page: 1)).getLeft().toNullable();

      for (final body in <Object>[
        {'content': []},
        [_summaryJson()..remove('name')],
        [_summaryJson(expirationDate: '15/09/2026')],
        [_summaryJson(price: '2.50')],
      ]) {
        final failure = await list(body);
        expect(failure, isA<ServerFailure>(), reason: '$body');
        expect(failure!.message, kServerMessage);
      }

      final details = (await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: _detailsJson()..['createdAt'] = 'yesterday',
        ),
      ).getProduct('p-1')).getLeft().toNullable();
      expect(details, isA<ServerFailure>());
    });
  });
}
