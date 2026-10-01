import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/guard_request.dart';
import '../../domain/entities/product_type_count.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  const DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<AdminFailure, List<ProductTypeCount>>> getProductTypeCounts() =>
      guardRequest(remoteDataSource.getProductTypeCounts);
}
