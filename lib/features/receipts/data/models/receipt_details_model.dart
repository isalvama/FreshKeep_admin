import '../../../../core/network/json_readers.dart';
import '../../../../shared/products/money_reader.dart';
import '../../domain/entities/receipt_details.dart';

class ReceiptDetailsModel extends ReceiptDetails {
  const ReceiptDetailsModel({
    required super.id,
    required super.creatorId,
    required super.creatorEmail,
    required super.creatorUsername,
    required super.spaceName,
    required super.storeName,
    required super.purchaseDate,
    required super.createdAt,
    required super.imageMimeType,
    required super.products,
  });

  /// `{id, creatorId, creatorUsername, creatorEmail, spaceId, spaceName,
  /// storeName, purchaseDate, createdAt, receiptImageId, receiptImageAssetId,
  /// receiptImageMimeType, products: [{id, name, expirationDate,
  /// actualStorageSpotId, productType, price, currency, deleted}]}`.
  factory ReceiptDetailsModel.fromJson(Map<String, dynamic> json) {
    final hasImage = json['receiptImageId'] != null;
    return ReceiptDetailsModel(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String?,
      creatorEmail: json['creatorEmail'] as String?,
      creatorUsername: json['creatorUsername'] as String?,
      spaceName: json['spaceName'] as String?,
      storeName: json['storeName'] as String?,
      purchaseDate: readCalendarDay(json['purchaseDate']),
      createdAt: readInstant(json['createdAt']),
      imageMimeType: hasImage ? json['receiptImageMimeType'] as String? : null,
      products: [
        for (final product in json['products'] as List)
          _product(product as Map<String, dynamic>),
      ],
    );
  }

  static ReceiptProduct _product(Map<String, dynamic> json) => ReceiptProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    productType: json['productType'] as String,
    expirationDate: readOptionalCalendarDay(json['expirationDate']),
    price: readMoney(json['price'], json['currency']),
    deleted: json['deleted'] as bool,
  );
}
