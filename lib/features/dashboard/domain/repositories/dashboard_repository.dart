import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/daily_count.dart';
import '../entities/date_range.dart';
import '../entities/product_type_count.dart';

/// Daily counts come back as the backend sends them: only days with
/// activity. The use cases fill the gaps.
abstract class DashboardRepository {
  Future<Either<AdminFailure, List<DailyCount>>> getUserRegistrations(
    DateRange range,
  );

  Future<Either<AdminFailure, List<DailyCount>>> getProductsAdded(
    DateRange range,
  );

  Future<Either<AdminFailure, List<DailyCount>>> getReceipts(DateRange range);

  Future<Either<AdminFailure, List<ProductTypeCount>>> getProductTypeCounts();
}
