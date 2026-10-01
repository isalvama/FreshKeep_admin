import 'package:dio/dio.dart';

import '../../domain/entities/date_range.dart';
import '../../domain/utils/calendar_day.dart';
import '../models/daily_count_model.dart';

const kUserRegistrationsPath = '/api/v1/admin/metrics/users/registrations';
const kProductsMetricPath = '/api/v1/admin/metrics/products';
const kReceiptsMetricPath = '/api/v1/admin/metrics/shopping-receipts';

class MetricsRemoteDataSource {
  final Dio dio;

  const MetricsRemoteDataSource(this.dio);

  Future<List<DailyCountModel>> getUserRegistrations(DateRange range) =>
      _getDailyCounts(kUserRegistrationsPath, range);

  Future<List<DailyCountModel>> getProductsAdded(
    DateRange range, {
    String? creatorId,
  }) => _getDailyCounts(kProductsMetricPath, range, creatorId: creatorId);

  Future<List<DailyCountModel>> getReceipts(
    DateRange range, {
    String? creatorId,
  }) => _getDailyCounts(
    kReceiptsMetricPath,
    range,
    creatorId: creatorId,
    countKey: 'totalReceipts',
  );

  Future<List<DailyCountModel>> _getDailyCounts(
    String path,
    DateRange range, {
    String? creatorId,
    String countKey = 'count',
  }) async {
    final response = await dio.get(
      path,
      queryParameters: {
        'from': isoDate(range.from),
        'to': isoDate(range.to),
        'creatorId': ?creatorId,
      },
    );
    return [
      for (final json in response.data as List)
        DailyCountModel.fromJson(
          json as Map<String, dynamic>,
          countKey: countKey,
        ),
    ];
  }
}
