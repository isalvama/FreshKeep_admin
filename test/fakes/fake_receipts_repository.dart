import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/receipts/domain/entities/receipt_details.dart';
import 'package:fresh_keep_admin/features/receipts/domain/entities/receipt_summary.dart';
import 'package:fresh_keep_admin/features/receipts/domain/entities/receipts_page.dart';
import 'package:fresh_keep_admin/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:fresh_keep_admin/shared/creators/domain/creator_label_repository.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/date_range.dart';
import 'package:fresh_keep_admin/shared/products/money.dart';

const kTestReceiptCreatorId = '3f2a9c1e-0b4d-4e8a-9f61-2c7d5e8b1a04';
const kTestReceiptId = 'd5b3e9c2-1111-4222-8333-944455556666';

/// Answers from settable results and records calls. Also answers the shared
/// creator-label lookup, so receipts tests drive the creator chip through
/// the same fake.
///
/// Each kind of call can be held (`hold…`): it then waits in the matching
/// `held…` list until a test completes it, in any order. Answers are read on
/// release, so a test can change them before completing a held call.
class FakeReceiptsRepository
    implements ReceiptsRepository, CreatorLabelRepository {
  Either<AdminFailure, ReceiptsPage> Function(
    DateRange range,
    String? creatorId,
    int page,
  )
  receiptsPage = (range, creatorId, page) =>
      Right(testReceiptsPage(page: page));
  Either<AdminFailure, ReceiptDetails> details = Right(testReceiptDetails());
  Either<AdminFailure, String> creatorEmail = const Right('alice@example.com');

  bool holdReceipts = false;
  bool holdDetails = false;
  bool holdLabels = false;
  final heldReceipts = <Completer<void>>[];
  final heldDetails = <Completer<void>>[];
  final heldLabels = <Completer<void>>[];

  final List<(DateRange, String?, int)> listCalls = [];
  final List<String> detailCalls = [];
  final List<String> creatorCalls = [];

  Future<void> _wait(bool hold, List<Completer<void>> held) async {
    if (!hold) return;
    final completer = Completer<void>();
    held.add(completer);
    await completer.future;
  }

  @override
  Future<Either<AdminFailure, ReceiptsPage>> getReceipts(
    DateRange purchasedBetween, {
    String? creatorId,
    required int page,
  }) async {
    listCalls.add((purchasedBetween, creatorId, page));
    await _wait(holdReceipts, heldReceipts);
    return receiptsPage(purchasedBetween, creatorId, page);
  }

  @override
  Future<Either<AdminFailure, ReceiptDetails>> getReceipt(
    String receiptId,
  ) async {
    detailCalls.add(receiptId);
    await _wait(holdDetails, heldDetails);
    return details;
  }

  @override
  Future<Either<AdminFailure, String>> getCreatorEmail(String userId) async {
    creatorCalls.add(userId);
    await _wait(holdLabels, heldLabels);
    return creatorEmail;
  }
}

/// Page [page] of [total] receipts, [kReceiptsPageSize] per page, newest
/// purchase first. Every 3rd receipt has no creator, space or store.
ReceiptsPage testReceiptsPage({int page = 1, int total = 75}) {
  final first = (page - 1) * kReceiptsPageSize;
  final count = (total - first).clamp(0, kReceiptsPageSize);
  final empty = count == 0;
  return ReceiptsPage(
    receipts: [
      for (var i = first; i < first + count; i++)
        ReceiptSummary(
          id: 'receipt-$i',
          creatorId: i % 3 == 2 ? null : 'user-$i',
          creatorEmail: i % 3 == 2 ? null : 'user$i@example.com',
          creatorUsername: i % 3 == 2 ? null : 'user$i',
          spaceName: i % 3 == 2 ? null : 'Kitchen',
          storeName: i % 3 == 2
              ? null
              : 'Store ${i.toString().padLeft(3, '0')}',
          purchaseDate: DateTime.utc(
            2026,
            9,
            30,
          ).subtract(Duration(days: i % 28)),
          productCount: i % 5,
        ),
    ],
    page: page,
    size: kReceiptsPageSize,
    totalElements: empty ? 0 : total,
    totalPages: empty ? 0 : (total / kReceiptsPageSize).ceil(),
  );
}

ReceiptDetails testReceiptDetails({
  String id = kTestReceiptId,
  List<ReceiptProduct>? products,
}) => ReceiptDetails(
  id: id,
  creatorId: kTestReceiptCreatorId,
  creatorEmail: 'alice@example.com',
  creatorUsername: 'alice',
  spaceName: 'Kitchen',
  storeName: 'SuperMart',
  purchaseDate: DateTime.utc(2026, 9, 8),
  createdAt: DateTime.utc(2026, 9, 8, 10, 15),
  imageMimeType: 'image/jpeg',
  products:
      products ??
      [
        ReceiptProduct(
          id: 'product-1',
          name: 'Milk',
          productType: 'DAIRY',
          expirationDate: DateTime.utc(2026, 10, 3),
          price: const Money(amount: 1.5, currency: 'USD'),
          deleted: false,
        ),
        ReceiptProduct(
          id: 'product-2',
          name: 'Bread',
          productType: 'BAKERY',
          expirationDate: DateTime.utc(2026, 9, 28),
          price: const Money(amount: 2.25, currency: 'USD'),
          deleted: false,
        ),
        const ReceiptProduct(
          id: 'product-3',
          name: 'Cheese',
          productType: 'DAIRY',
          expirationDate: null,
          price: null,
          deleted: false,
        ),
        ReceiptProduct(
          id: 'product-4',
          name: 'Salmon',
          productType: 'SEAFOOD',
          expirationDate: DateTime.utc(2026, 9, 20),
          price: const Money(amount: 9.99, currency: 'USD'),
          deleted: true,
        ),
      ],
);
