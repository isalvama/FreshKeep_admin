import 'package:equatable/equatable.dart';

import '../../../../shared/products/product_type.dart';

class ProductTypeCount extends Equatable {
  /// Raw backend value, e.g. `OTHER_FRESH_PRODUCTS`.
  final String productType;
  final int count;

  const ProductTypeCount({required this.productType, required this.count});

  /// `OTHER_FRESH_PRODUCTS` → "Other fresh products".
  String get label => productTypeLabel(productType);

  @override
  List<Object?> get props => [productType, count];
}
