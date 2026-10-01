import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/daily_count.dart';
import '../entities/date_range.dart';

/// Daily activity counts. They come back as the backend sends them: only
/// days with activity. The use cases fill the gaps.
///
/// [creatorId] (a user id) narrows products and receipts to one user.
abstract class MetricsRepository {
  Future<Either<AdminFailure, List<DailyCount>>> getUserRegistrations(
    DateRange range,
  );

  Future<Either<AdminFailure, List<DailyCount>>> getProductsAdded(
    DateRange range, {
    String? creatorId,
  });

  Future<Either<AdminFailure, List<DailyCount>>> getReceipts(
    DateRange range, {
    String? creatorId,
  });
}
