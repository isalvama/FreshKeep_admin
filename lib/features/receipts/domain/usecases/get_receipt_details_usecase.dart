import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/receipt_details.dart';
import '../repositories/receipts_repository.dart';

class GetReceiptDetailsUseCase {
  final ReceiptsRepository repository;

  const GetReceiptDetailsUseCase(this.repository);

  Future<Either<AdminFailure, ReceiptDetails>> call(String receiptId) =>
      repository.getReceipt(receiptId);
}
