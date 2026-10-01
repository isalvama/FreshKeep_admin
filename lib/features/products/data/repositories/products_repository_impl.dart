import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/guard_request.dart';
import '../../domain/entities/product_details.dart';
import '../../domain/entities/product_filters.dart';
import '../../domain/entities/products_page.dart';
import '../../domain/entities/receipt_label.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_remote_datasource.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource remoteDataSource;

  const ProductsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<AdminFailure, ProductsPage>> getProducts(
    ProductFilters filters, {
    required int page,
  }) => guardRequest(() async {
    final products = await remoteDataSource.getProducts(
      filters,
      page: page,
      size: kProductsPageSize,
    );
    return ProductsPage(
      products: products,
      page: page,
      size: kProductsPageSize,
    );
  });

  @override
  Future<Either<AdminFailure, ProductDetails>> getProduct(String productId) =>
      guardRequest(() => remoteDataSource.getProduct(productId));

  @override
  Future<Either<AdminFailure, ReceiptLabel>> getReceiptLabel(
    String receiptId,
  ) => guardRequest(() => remoteDataSource.getReceiptLabel(receiptId));
}
