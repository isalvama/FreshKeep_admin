import 'package:equatable/equatable.dart';

class ProductTypeCount extends Equatable {
  /// Raw backend value, e.g. `OTHER_FRESH_PRODUCTS`.
  final String productType;
  final int count;

  const ProductTypeCount({required this.productType, required this.count});

  /// `OTHER_FRESH_PRODUCTS` → "Other fresh products". Derived from the raw
  /// value, so types the app doesn't know yet still read well.
  String get label {
    final words = productType.toLowerCase().replaceAll('_', ' ').trim();
    if (words.isEmpty) return productType;
    return words[0].toUpperCase() + words.substring(1);
  }

  @override
  List<Object?> get props => [productType, count];
}
