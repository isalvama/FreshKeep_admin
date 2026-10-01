import 'package:dio/dio.dart';

import '../models/product_type_count_model.dart';

const kProductTypesPath = '/api/v1/admin/product-types';

class DashboardRemoteDataSource {
  final Dio dio;

  const DashboardRemoteDataSource(this.dio);

  Future<List<ProductTypeCountModel>> getProductTypeCounts() async {
    final response = await dio.get(kProductTypesPath);
    return [
      for (final json in response.data as List)
        ProductTypeCountModel.fromJson(json as Map<String, dynamic>),
    ];
  }
}
