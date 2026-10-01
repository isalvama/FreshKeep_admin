import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../entities/receipts_page.dart';
import '../repositories/receipts_repository.dart';

/// One page of the receipts list. (The daily receipt counts behind the
/// charts are the shared metrics' `GetReceiptsUseCase`.)
class GetReceiptsListUseCase {
  final ReceiptsRepository repository;

  const GetReceiptsListUseCase(this.repository);

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
