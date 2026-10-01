import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/guard_request.dart';
import '../../domain/entities/daily_count.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/repositories/metrics_repository.dart';
import '../datasources/metrics_remote_datasource.dart';

class MetricsRepositoryImpl implements MetricsRepository {
  final MetricsRemoteDataSource remoteDataSource;

  const MetricsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<AdminFailure, List<DailyCount>>> getUserRegistrations(
    DateRange range,
  ) => guardRequest(() => remoteDataSource.getUserRegistrations(range));

  @override
  Future<Either<AdminFailure, List<DailyCount>>> getProductsAdded(
    DateRange range, {
    String? creatorId,
  }) => guardRequest(
    () => remoteDataSource.getProductsAdded(range, creatorId: creatorId),
  );

  @override
  Future<Either<AdminFailure, List<DailyCount>>> getReceipts(
    DateRange range, {
    String? creatorId,
  }) => guardRequest(
    () => remoteDataSource.getReceipts(range, creatorId: creatorId),
  );
}
