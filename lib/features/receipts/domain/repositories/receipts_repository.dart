import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../entities/receipt_details.dart';
import '../entities/receipts_page.dart';

/// Receipts per page, the backend's default.
const kReceiptsPageSize = 30;

abstract class ReceiptsRepository {
  /// Receipts purchased in [purchasedBetween], newest purchase first,
  /// optionally only those [creatorId] (`users.id`) uploaded; [page] is
  /// 1-based.
  Future<Either<AdminFailure, ReceiptsPage>> getReceipts(
    DateRange purchasedBetween, {
    String? creatorId,
    required int page,
  });

  /// A missing receipt (or a malformed id) fails with [ValidationFailure]:
  /// the backend answers 400 for both.
  Future<Either<AdminFailure, ReceiptDetails>> getReceipt(String receiptId);
}
