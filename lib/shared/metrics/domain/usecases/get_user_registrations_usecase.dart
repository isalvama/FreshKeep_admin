import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/daily_count.dart';
import '../entities/date_range.dart';
import '../repositories/metrics_repository.dart';
import '../utils/fill_missing_days.dart';

class GetUserRegistrationsUseCase {
  final MetricsRepository repository;

  const GetUserRegistrationsUseCase(this.repository);

  /// Every day of [range] has an entry: days the backend omitted are 0.
  Future<Either<AdminFailure, List<DailyCount>>> call(DateRange range) async =>
      (await repository.getUserRegistrations(
        range,
      )).map((counts) => fillMissingDays(counts, range));
}
