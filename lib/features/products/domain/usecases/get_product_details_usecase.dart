import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/product_details.dart';
import '../repositories/products_repository.dart';

class GetProductDetailsUseCase {
  final ProductsRepository repository;

  const GetProductDetailsUseCase(this.repository);

  Future<Either<AdminFailure, ProductDetails>> call(String productId) =>
      repository.getProduct(productId);
}
