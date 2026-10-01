import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/receipt_label.dart';
import '../repositories/products_repository.dart';

class GetReceiptLabelUseCase {
  final ProductsRepository repository;

  const GetReceiptLabelUseCase(this.repository);

  Future<Either<AdminFailure, ReceiptLabel>> call(String receiptId) =>
      repository.getReceiptLabel(receiptId);
}
