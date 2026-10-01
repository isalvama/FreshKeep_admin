import '../../domain/entities/product_type_count.dart';

class ProductTypeCountModel extends ProductTypeCount {
  const ProductTypeCountModel({
    required super.productType,
    required super.count,
  });

  /// `{"productType": "DAIRY", "productCount": 12}`.
  factory ProductTypeCountModel.fromJson(Map<String, dynamic> json) {
    return ProductTypeCountModel(
      productType: json['productType'] as String,
      count: (json['productCount'] as num).toInt(),
    );
  }
}
