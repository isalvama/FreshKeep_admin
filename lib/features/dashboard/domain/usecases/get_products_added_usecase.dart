import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/daily_count.dart';
import '../entities/date_range.dart';
import '../repositories/dashboard_repository.dart';
import '../utils/fill_missing_days.dart';

class GetProductsAddedUseCase {
  final DashboardRepository repository;

  const GetProductsAddedUseCase(this.repository);

  /// Every day of [range] has an entry: days the backend omitted are 0.
  Future<Either<AdminFailure, List<DailyCount>>> call(DateRange range) async =>
      (await repository.getProductsAdded(
        range,
      )).map((counts) => fillMissingDays(counts, range));
}
