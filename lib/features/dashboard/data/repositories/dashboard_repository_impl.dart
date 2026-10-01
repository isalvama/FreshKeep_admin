import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/daily_count.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/product_type_count.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  const DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<AdminFailure, List<DailyCount>>> getUserRegistrations(
    DateRange range,
  ) => _guard(() => remoteDataSource.getUserRegistrations(range));

  @override
  Future<Either<AdminFailure, List<DailyCount>>> getProductsAdded(
    DateRange range,
  ) => _guard(() => remoteDataSource.getProductsAdded(range));

  @override
  Future<Either<AdminFailure, List<DailyCount>>> getReceipts(DateRange range) =>
      _guard(() => remoteDataSource.getReceipts(range));

  @override
  Future<Either<AdminFailure, List<ProductTypeCount>>> getProductTypeCounts() =>
      _guard(remoteDataSource.getProductTypeCounts);

  Future<Either<AdminFailure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on DioException catch (e) {
      return Left(mapDioException(e));
    } on FormatException {
      // The backend answered with a shape we can't read — not fixable by the admin.
      return const Left(ServerFailure(kServerMessage));
    } on TypeError {
      return const Left(ServerFailure(kServerMessage));
    }
  }
}
