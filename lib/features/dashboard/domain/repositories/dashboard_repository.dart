import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/product_type_count.dart';

/// Dashboard-only data. The daily metrics live in the shared
/// `MetricsRepository`.
abstract class DashboardRepository {
  Future<Either<AdminFailure, List<ProductTypeCount>>> getProductTypeCounts();
}
