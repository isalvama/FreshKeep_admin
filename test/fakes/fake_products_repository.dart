import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/shared/products/money.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_details.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_filters.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_summary.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/products_page.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/receipt_label.dart';
import 'package:fresh_keep_admin/features/products/domain/repositories/products_repository.dart';
import 'package:fresh_keep_admin/shared/creators/domain/creator_label_repository.dart';

const kTestCreatorId = '3f2a9c1e-0b4d-4e8a-9f61-2c7d5e8b1a04';
const kTestReceiptId = 'd5b3e9c2-1111-4222-8333-944455556666';

/// Answers from settable results and records calls.
///
/// Each kind of call can be held (`hold…`): it then waits in the matching
/// `held…` list until a test completes it, in any order. Answers are read on
/// release, so a test can change them before completing a held call.
/// Also answers the shared creator-label lookup, so products tests drive the
/// creator chip through the same fake.
class FakeProductsRepository
    implements ProductsRepository, CreatorLabelRepository {
  Either<AdminFailure, ProductsPage> Function(ProductFilters filters, int page)
  productsPage = (filters, page) => Right(testProductsPage(page: page));
  Either<AdminFailure, ProductDetails> details = Right(testProductDetails());
  Either<AdminFailure, String> creatorEmail = const Right('alice@example.com');
  Either<AdminFailure, ReceiptLabel> receiptLabel = Right(testReceiptLabel);

  bool holdProducts = false;
  bool holdDetails = false;
  bool holdLabels = false;
  final heldProducts = <Completer<void>>[];
  final heldDetails = <Completer<void>>[];
  final heldLabels = <Completer<void>>[];

  final List<(ProductFilters, int)> listCalls = [];
  final List<String> detailCalls = [];
  final List<String> creatorCalls = [];
  final List<String> receiptCalls = [];

  Future<void> _wait(bool hold, List<Completer<void>> held) async {
    if (!hold) return;
    final completer = Completer<void>();
    held.add(completer);
    await completer.future;
  }

  @override
  Future<Either<AdminFailure, ProductsPage>> getProducts(
    ProductFilters filters, {
    required int page,
  }) async {
    listCalls.add((filters, page));
    await _wait(holdProducts, heldProducts);
    return productsPage(filters, page);
  }

  @override
  Future<Either<AdminFailure, ProductDetails>> getProduct(
    String productId,
  ) async {
    detailCalls.add(productId);
    await _wait(holdDetails, heldDetails);
    return details;
  }

  @override
  Future<Either<AdminFailure, String>> getCreatorEmail(String userId) async {
    creatorCalls.add(userId);
    await _wait(holdLabels, heldLabels);
    return creatorEmail;
  }

  @override
  Future<Either<AdminFailure, ReceiptLabel>> getReceiptLabel(
    String receiptId,
  ) async {
    receiptCalls.add(receiptId);
    await _wait(holdLabels, heldLabels);
    return receiptLabel;
  }
}

final testReceiptLabel = ReceiptLabel(
  storeName: 'SuperMart',
  purchaseDate: DateTime.utc(2026, 9, 8),
);

/// Page [page] of [total] products, [kProductsPageSize] per page. Rows cycle
/// through an expired one, one expiring soon (relative to 2026-10-01), one
/// without a date and one without a price.
ProductsPage testProductsPage({int page = 1, int total = 75}) {
  final first = (page - 1) * kProductsPageSize;
  final count = (total - first).clamp(0, kProductsPageSize);
  return ProductsPage(
    products: [
      for (var i = first; i < first + count; i++)
        ProductSummary(
          id: 'product-$i',
          name: 'Product ${i.toString().padLeft(3, '0')}',
          productType: i.isEven ? 'DAIRY' : 'OTHER_FRESH_PRODUCTS',
          expirationDate: switch (i % 4) {
            0 => DateTime.utc(2026, 9, 28),
            1 => DateTime.utc(2026, 10, 3),
            2 => null,
            _ => DateTime.utc(2026, 11, 20),
          },
          price: i % 4 == 3 ? null : Money(amount: 1.5 + i, currency: 'USD'),
        ),
    ],
    page: page,
    size: kProductsPageSize,
  );
}

ProductDetails testProductDetails({
  String id = 'product-1',
  bool withOrigin = true,
}) => ProductDetails(
  id: id,
  name: 'Milk',
  productType: 'DAIRY',
  expirationDate: DateTime.utc(2026, 10, 3),
  storageSpotType: 'FRIDGE',
  price: const Money(amount: 2.5, currency: 'USD'),
  createdAt: DateTime.utc(2026, 9, 8, 10, 15),
  origin: withOrigin
      ? ProductOrigin(
          receiptId: kTestReceiptId,
          creatorId: kTestCreatorId,
          creatorEmail: 'alice@example.com',
          creatorUsername: 'alice',
          spaceName: 'Kitchen',
          storeName: 'SuperMart',
          purchaseDate: DateTime.utc(2026, 9, 8),
        )
      : null,
);
