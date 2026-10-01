import 'package:dio/dio.dart';

import '../../../../core/network/admin_api_paths.dart';
import '../../domain/entities/product_filters.dart';
import '../models/product_details_model.dart';
import '../models/product_summary_model.dart';
import '../models/receipt_label_model.dart';

class ProductsRemoteDataSource {
  final Dio dio;

  const ProductsRemoteDataSource(this.dio);

  Future<List<ProductSummaryModel>> getProducts(
    ProductFilters filters, {
    required int page,
    required int size,
  }) async {
    final response = await dio.get(
      kAdminProductsApiPath,
      queryParameters: {
        'sort': filters.sort.backendValue,
        'page': page,
        'size': size,
        'productType': ?filters.productType,
        'creatorId': ?filters.creatorId,
        'shoppingReceiptId': ?filters.receiptId,
      },
    );
    return [
      for (final product in response.data as List)
        ProductSummaryModel.fromJson(product as Map<String, dynamic>),
    ];
  }

  // Ids come from the URL bar: encode them so each can only ever be one path
  // segment (e.g. "../users" can't reach another endpoint).

  Future<ProductDetailsModel> getProduct(String productId) async {
    final response = await dio.get(
      '$kAdminProductsApiPath/${Uri.encodeComponent(productId)}',
    );
    return ProductDetailsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReceiptLabelModel> getReceiptLabel(String receiptId) async {
    final response = await dio.get(
      '$kAdminShoppingReceiptsApiPath/${Uri.encodeComponent(receiptId)}',
    );
    return ReceiptLabelModel.fromJson(response.data as Map<String, dynamic>);
  }
}
