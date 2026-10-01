import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/product_filters.dart';
import '../entities/products_page.dart';
import '../repositories/products_repository.dart';

class GetProductsUseCase {
  final ProductsRepository repository;

  const GetProductsUseCase(this.repository);

  Future<Either<AdminFailure, ProductsPage>> call(
    ProductFilters filters, {
    required int page,
  }) => repository.getProducts(filters, page: page);
}
