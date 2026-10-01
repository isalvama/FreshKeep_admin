import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../entities/receipts_page.dart';
import '../repositories/receipts_repository.dart';

class GetReceiptsUseCase {
  final ReceiptsRepository repository;

  const GetReceiptsUseCase(this.repository);

  Future<Either<AdminFailure, ReceiptsPage>> call(
    DateRange purchasedBetween, {
    String? creatorId,
    required int page,
  }) => repository.getReceipts(
    purchasedBetween,
    creatorId: creatorId,
    page: page,
  );
}
