import '../../../../core/network/json_readers.dart';
import '../../domain/entities/product_details.dart';
import 'money_reader.dart';

class ProductDetailsModel extends ProductDetails {
  const ProductDetailsModel({
    required super.id,
    required super.name,
    required super.productType,
    required super.expirationDate,
    required super.storageSpotType,
    required super.price,
    required super.createdAt,
    required super.origin,
  });

  /// `{id, name, productType, expirationDate, actualStorageSpotId,
  /// storageSpotIdType, creatorId, creatorUsername, creatorEmail, spaceId,
  /// spaceName, storeName, purchaseDate, createdAt, shoppingReceiptId, price,
  /// currency}`. Everything about the origin comes from the receipt, so it is
  /// null without one.
  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    final receiptId = json['shoppingReceiptId'] as String?;
    return ProductDetailsModel(
      id: json['id'] as String,
      name: json['name'] as String,
      productType: json['productType'] as String,
      expirationDate: readOptionalCalendarDay(json['expirationDate']),
      storageSpotType: json['storageSpotIdType'] as String?,
      price: readMoney(json['price'], json['currency']),
      createdAt: readInstant(json['createdAt']),
      origin: receiptId == null
          ? null
          : ProductOrigin(
              receiptId: receiptId,
              creatorId: json['creatorId'] as String?,
              creatorEmail: json['creatorEmail'] as String?,
              creatorUsername: json['creatorUsername'] as String?,
              spaceName: json['spaceName'] as String?,
              storeName: json['storeName'] as String?,
              purchaseDate: readOptionalCalendarDay(json['purchaseDate']),
            ),
    );
  }
}
