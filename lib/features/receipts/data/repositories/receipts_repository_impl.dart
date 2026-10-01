import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/guard_request.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../../domain/entities/receipt_details.dart';
import '../../domain/entities/receipts_page.dart';
import '../../domain/repositories/receipts_repository.dart';
import '../datasources/receipts_remote_datasource.dart';

class ReceiptsRepositoryImpl implements ReceiptsRepository {
  final ReceiptsRemoteDataSource remoteDataSource;

  const ReceiptsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<AdminFailure, ReceiptsPage>> getReceipts(
    DateRange purchasedBetween, {
    String? creatorId,
    required int page,
  }) => guardRequest(
    () => remoteDataSource.getReceipts(
      purchasedBetween,
      creatorId: creatorId,
      page: page,
    ),
  );

  @override
  Future<Either<AdminFailure, ReceiptDetails>> getReceipt(String receiptId) =>
      guardRequest(() => remoteDataSource.getReceipt(receiptId));
}
