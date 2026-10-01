import 'package:dio/dio.dart';

import '../../domain/entities/product_filters.dart';
import '../models/product_details_model.dart';
import '../models/product_summary_model.dart';
import '../models/receipt_label_model.dart';

const kProductsApiPath = '/api/v1/admin/products';
const kAdminUsersApiPath = '/api/v1/admin/users';
const kShoppingReceiptsApiPath = '/api/v1/admin/shopping-receipts';

class ProductsRemoteDataSource {
  final Dio dio;

  const ProductsRemoteDataSource(this.dio);

  Future<List<ProductSummaryModel>> getProducts(
    ProductFilters filters, {
    required int page,
    required int size,
  }) async {
    final response = await dio.get(
      kProductsApiPath,
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
      '$kProductsApiPath/${Uri.encodeComponent(productId)}',
    );
    return ProductDetailsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> getUserEmail(String userId) async {
    final response = await dio.get(
      '$kAdminUsersApiPath/${Uri.encodeComponent(userId)}',
    );
    return (response.data as Map<String, dynamic>)['email'] as String;
  }

  Future<ReceiptLabelModel> getReceiptLabel(String receiptId) async {
    final response = await dio.get(
      '$kShoppingReceiptsApiPath/${Uri.encodeComponent(receiptId)}',
    );
    return ReceiptLabelModel.fromJson(response.data as Map<String, dynamic>);
  }
}
