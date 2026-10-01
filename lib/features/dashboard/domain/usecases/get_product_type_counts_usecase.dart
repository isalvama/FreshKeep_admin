import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/product_type_count.dart';
import '../repositories/dashboard_repository.dart';

class GetProductTypeCountsUseCase {
  final DashboardRepository repository;

  const GetProductTypeCountsUseCase(this.repository);

  /// Largest count first; ties by label, so the order is stable.
  Future<Either<AdminFailure, List<ProductTypeCount>>> call() async =>
      (await repository.getProductTypeCounts()).map(
        (counts) => [...counts]
          ..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            return byCount != 0 ? byCount : a.label.compareTo(b.label);
          }),
      );
}
