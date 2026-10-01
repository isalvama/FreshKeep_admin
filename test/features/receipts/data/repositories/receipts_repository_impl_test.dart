import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/dio_failure_mapper.dart';
import 'package:fresh_keep_admin/features/receipts/data/datasources/receipts_remote_datasource.dart';
import 'package:fresh_keep_admin/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:fresh_keep_admin/features/receipts/domain/entities/receipt_details.dart';
import 'package:fresh_keep_admin/features/receipts/domain/entities/receipt_summary.dart';
import 'package:fresh_keep_admin/features/receipts/domain/usecases/get_receipt_details_usecase.dart';
import 'package:fresh_keep_admin/features/receipts/domain/usecases/get_receipts_list_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/date_range.dart';
import 'package:fresh_keep_admin/shared/products/money.dart';

import '../../../../fakes/fake_http_adapter.dart';

final _range = DateRange(
  from: DateTime.utc(2026, 9, 2),
  to: DateTime.utc(2026, 10, 1),
);

ReceiptsRepositoryImpl _repository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8082'))
    ..httpClientAdapter = adapter;
  return ReceiptsRepositoryImpl(
    remoteDataSource: ReceiptsRemoteDataSource(dio),
  );
}

Map<String, dynamic> _summaryJson({
  Object? creatorId = 'u-1',
  Object? creatorEmail = 'alice@example.com',
  Object? spaceName = 'Kitchen',
  Object? storeName = 'SuperMart',
}) => {
  'id': 'r-1',
  'creatorId': creatorId,
  'creatorEmail': creatorEmail,
  'creatorUsername': 'alice',
  'spaceId': 's-1',
  'spaceName': spaceName,
  'storeName': storeName,
  'purchaseDate': '2026-09-08',
  'createdAt': '2026-09-08T10:00:00Z',
  'productCount': 4,
};

Map<String, dynamic> _pageJson({List<Object>? content}) => {
  'content': content ?? [_summaryJson()],
  'page': 2,
  'size': 30,
  'totalElements': 61,
  'totalPages': 3,
};

Map<String, dynamic> _productJson({
  String id = 'p-1',
  Object? price = 2.5,
  Object? deleted = false,
}) => {
  'id': id,
  'name': 'Milk',
  'expirationDate': '2026-09-15',
  'actualStorageSpotId': 'spot-1',
  'productType': 'DAIRY',
  'price': price,
  'currency': 'USD',
  'deleted': deleted,
};

Map<String, dynamic> _detailsJson({
  Object? receiptImageId = 'img-1',
  List<Object>? products,
}) => {
  'id': 'r-1',
  'creatorId': 'u-1',
  'creatorUsername': 'alice',
  'creatorEmail': 'alice@example.com',
  'spaceId': 's-1',
  'spaceName': 'Kitchen',
  'storeName': 'SuperMart',
  'purchaseDate': '2026-09-08',
  'createdAt': '2026-09-08T10:00:00Z',
  'receiptImageId': receiptImageId,
  'receiptImageAssetId': 'shopping_receipts/receipts/abc',
  'receiptImageMimeType': 'image/jpeg',
  'products':
      products ??
      [_productJson(), _productJson(id: 'p-2', price: null, deleted: true)],
};

void main() {
  group('getReceipts', () {
    test('sends from, to, page and size=30; userId only when set', () async {
      final adapter = JsonResponseAdapter(statusCode: 200, body: _pageJson());

      await _repository(adapter).getReceipts(_range, page: 2);
      await GetReceiptsListUseCase(_repository(adapter))(
        _range,
        creatorId: 'u-1',
        page: 1,
      );

      expect(adapter.requests[0].path, '/api/v1/admin/shopping-receipts');
      expect(adapter.requests[0].queryParameters, {
        'from': '2026-09-02',
        'to': '2026-10-01',
        'page': 2,
        'size': 30,
      });
      expect(adapter.requests[1].queryParameters, {
        'from': '2026-09-02',
        'to': '2026-10-01',
        'userId': 'u-1',
        'page': 1,
        'size': 30,
      });
    });

    test('parses the page and its rows', () async {
      final page = (await _repository(
        JsonResponseAdapter(statusCode: 200, body: _pageJson()),
      ).getReceipts(_range, page: 2)).getRight().toNullable()!;

      expect(
        (page.page, page.size, page.totalElements, page.totalPages),
        (2, 30, 61, 3),
      );
      expect(
        page.receipts.single.props,
        ReceiptSummary(
          id: 'r-1',
          creatorId: 'u-1',
          creatorEmail: 'alice@example.com',
          creatorUsername: 'alice',
          spaceName: 'Kitchen',
          storeName: 'SuperMart',
          purchaseDate: DateTime.utc(2026, 9, 8),
          productCount: 4,
        ).props,
      );
    });

    test('accepts a missing creator, space and store', () async {
      final receipt = (await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: _pageJson(
            content: [
              _summaryJson(
                creatorId: null,
                creatorEmail: null,
                spaceName: null,
                storeName: null,
              )..['creatorUsername'] = null,
            ],
          ),
        ),
      ).getReceipts(_range, page: 1)).getRight().toNullable()!.receipts.single;

      expect(receipt.creatorId, isNull);
      expect(receipt.creatorEmail, isNull);
      expect(receipt.creatorUsername, isNull);
      expect(receipt.spaceName, isNull);
      expect(receipt.storeName, isNull);
    });
  });

  group('getReceipt', () {
    test(
      'GETs /api/v1/admin/shopping-receipts/{id}, encoding the id',
      () async {
        final adapter = JsonResponseAdapter(
          statusCode: 200,
          body: _detailsJson(),
        );

        await _repository(adapter).getReceipt('r-1');
        await _repository(adapter).getReceipt('../products');

        expect(adapter.requests.map((r) => r.path), [
          '/api/v1/admin/shopping-receipts/r-1',
          '/api/v1/admin/shopping-receipts/..%2Fproducts',
        ]);
      },
    );

    test('parses the receipt, its image and its products', () async {
      final receipt = (await GetReceiptDetailsUseCase(
        _repository(JsonResponseAdapter(statusCode: 200, body: _detailsJson())),
      )('r-1')).getRight().toNullable()!;

      expect(receipt.creatorEmail, 'alice@example.com');
      expect(receipt.spaceName, 'Kitchen');
      expect(receipt.purchaseDate, DateTime.utc(2026, 9, 8));
      expect(receipt.createdAt, DateTime.utc(2026, 9, 8, 10));
      expect(receipt.imageMimeType, 'image/jpeg');
      expect(receipt.products, [
        ReceiptProduct(
          id: 'p-1',
          name: 'Milk',
          productType: 'DAIRY',
          expirationDate: DateTime.utc(2026, 9, 15),
          price: const Money(amount: 2.5, currency: 'USD'),
          deleted: false,
        ),
        ReceiptProduct(
          id: 'p-2',
          name: 'Milk',
          productType: 'DAIRY',
          expirationDate: DateTime.utc(2026, 9, 15),
          price: null,
          deleted: true,
        ),
      ]);
    });

    test('a receipt without an image has no image type', () async {
      final receipt = (await _repository(
        JsonResponseAdapter(
          statusCode: 200,
          body: _detailsJson(receiptImageId: null),
        ),
      ).getReceipt('r-1')).getRight().toNullable()!;

      expect(receipt.imageMimeType, isNull);
    });
  });

  group('failures', () {
    test(
      'a missing receipt (400) is a ValidationFailure with the detail',
      () async {
        final failure = (await _repository(
          JsonResponseAdapter(
            statusCode: 400,
            body: {'detail': 'Shopping receipt with id r-9 does not exist.'},
          ),
        ).getReceipt('r-9')).getLeft().toNullable()!;

        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Shopping receipt with id r-9 does not exist.');
      },
    );

    test('401, 500 and network errors map through the shared mapper', () async {
      Future<AdminFailure> fail(HttpClientAdapter a) async =>
          (await _repository(
            a,
          ).getReceipts(_range, page: 1)).getLeft().toNullable()!;

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
        // The pre-SPEC-02 backend: a plain array.
        [_summaryJson()],
        _pageJson(content: [_summaryJson()..remove('productCount')]),
        _pageJson(content: [_summaryJson()..['purchaseDate'] = '08/09/2026']),
        _pageJson()..remove('totalPages'),
      ]) {
        final failure = (await _repository(
          JsonResponseAdapter(statusCode: 200, body: body),
        ).getReceipts(_range, page: 1)).getLeft().toNullable();

        expect(failure, isA<ServerFailure>(), reason: '$body');
        expect(failure!.message, kServerMessage);
      }

      for (final products in [
        [_productJson()..remove('deleted')],
        [_productJson(deleted: 'no')],
      ]) {
        final failure = (await _repository(
          JsonResponseAdapter(
            statusCode: 200,
            body: _detailsJson(products: products),
          ),
        ).getReceipt('r-1')).getLeft().toNullable();

        expect(failure, isA<ServerFailure>(), reason: '$products');
      }
    });
  });
}
