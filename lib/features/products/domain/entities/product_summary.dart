import 'package:equatable/equatable.dart';

import '../../../../shared/products/money.dart';

/// One row of the products list.
class ProductSummary extends Equatable {
  final String id;
  final String name;

  /// Raw backend value, e.g. `OTHER_FRESH_PRODUCTS`.
  final String productType;

  /// A calendar day (UTC midnight).
  final DateTime? expirationDate;
  final Money? price;

  const ProductSummary({
    required this.id,
    required this.name,
    required this.productType,
    required this.expirationDate,
    required this.price,
  });

  @override
  List<Object?> get props => [id, name, productType, expirationDate, price];
}
