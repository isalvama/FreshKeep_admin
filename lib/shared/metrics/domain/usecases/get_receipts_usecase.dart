import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/daily_count.dart';
import '../entities/date_range.dart';
import '../repositories/metrics_repository.dart';
import '../utils/fill_missing_days.dart';

class GetReceiptsUseCase {
  final MetricsRepository repository;

  const GetReceiptsUseCase(this.repository);

  /// Every day of [range] has an entry: days the backend omitted are 0.
  /// [creatorId] narrows the counts to one user's activity.
  Future<Either<AdminFailure, List<DailyCount>>> call(
    DateRange range, {
    String? creatorId,
  }) async => (await repository.getReceipts(
    range,
    creatorId: creatorId,
  )).map((counts) => fillMissingDays(counts, range));
}
