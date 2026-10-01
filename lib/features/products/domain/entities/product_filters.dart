import 'package:equatable/equatable.dart';

import 'product_sort.dart';

/// What the products list shows: an order plus optional filters.
class ProductFilters extends Equatable {
  final ProductSort sort;

  /// A raw backend type, e.g. `DAIRY`.
  final String? productType;

  /// Products on receipts this user (`users.id`) created.
  final String? creatorId;

  /// Products on this shopping receipt.
  final String? receiptId;

  const ProductFilters({
    this.sort = ProductSort.nameAsc,
    this.productType,
    this.creatorId,
    this.receiptId,
  });

  @override
  List<Object?> get props => [sort, productType, creatorId, receiptId];
}
