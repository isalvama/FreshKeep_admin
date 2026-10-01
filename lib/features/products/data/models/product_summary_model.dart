import '../../../../core/network/json_readers.dart';
import '../../domain/entities/product_summary.dart';
import 'money_reader.dart';

class ProductSummaryModel extends ProductSummary {
  const ProductSummaryModel({
    required super.id,
    required super.name,
    required super.productType,
    required super.expirationDate,
    required super.price,
  });

  /// `{id, name, expirationDate, actualStorageSpotId, productType,
  /// shoppingReceiptId, price, currency}`.
  factory ProductSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProductSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      productType: json['productType'] as String,
      expirationDate: readOptionalCalendarDay(json['expirationDate']),
      price: readMoney(json['price'], json['currency']),
    );
  }
}
