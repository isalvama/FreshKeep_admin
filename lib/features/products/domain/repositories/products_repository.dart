import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/product_details.dart';
import '../entities/product_filters.dart';
import '../entities/products_page.dart';
import '../entities/receipt_label.dart';

/// Products per page, the backend's default.
const kProductsPageSize = 30;

abstract class ProductsRepository {
  /// [page] is 1-based.
  Future<Either<AdminFailure, ProductsPage>> getProducts(
    ProductFilters filters, {
    required int page,
  });

  /// A missing product (or a malformed id) fails with [ValidationFailure]:
  /// the backend answers 400 for both.
  Future<Either<AdminFailure, ProductDetails>> getProduct(String productId);

  /// The email of the user (`users.id`), for the creator filter chip.
  Future<Either<AdminFailure, String>> getCreatorEmail(String userId);

  /// The store and purchase date of a receipt, for the receipt filter chip.
  Future<Either<AdminFailure, ReceiptLabel>> getReceiptLabel(String receiptId);
}
