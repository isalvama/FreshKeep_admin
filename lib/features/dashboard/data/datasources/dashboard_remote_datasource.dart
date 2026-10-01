import 'package:dio/dio.dart';

import '../../domain/entities/date_range.dart';
import '../../domain/utils/calendar_day.dart';
import '../models/daily_count_model.dart';
import '../models/product_type_count_model.dart';

const kUserRegistrationsPath = '/api/v1/admin/metrics/users/registrations';
const kProductsMetricPath = '/api/v1/admin/metrics/products';
const kReceiptsMetricPath = '/api/v1/admin/metrics/shopping-receipts';
const kProductTypesPath = '/api/v1/admin/product-types';

class DashboardRemoteDataSource {
  final Dio dio;

  const DashboardRemoteDataSource(this.dio);

  Future<List<DailyCountModel>> getUserRegistrations(DateRange range) =>
      _getDailyCounts(kUserRegistrationsPath, range);

  Future<List<DailyCountModel>> getProductsAdded(DateRange range) =>
      _getDailyCounts(kProductsMetricPath, range);

  Future<List<DailyCountModel>> getReceipts(DateRange range) =>
      _getDailyCounts(kReceiptsMetricPath, range, countKey: 'totalReceipts');

  Future<List<ProductTypeCountModel>> getProductTypeCounts() async {
    final response = await dio.get(kProductTypesPath);
    return [
      for (final json in response.data as List)
        ProductTypeCountModel.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<List<DailyCountModel>> _getDailyCounts(
    String path,
    DateRange range, {
    String countKey = 'count',
  }) async {
    final response = await dio.get(
      path,
      queryParameters: {'from': isoDate(range.from), 'to': isoDate(range.to)},
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
