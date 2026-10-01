import 'package:equatable/equatable.dart';

import 'money.dart';

class ProductDetails extends Equatable {
  final String id;
  final String name;

  /// Raw backend value, e.g. `DAIRY`.
  final String productType;

  /// A calendar day (UTC midnight).
  final DateTime? expirationDate;

  /// Raw backend value, e.g. `FRIDGE`.
  final String? storageSpotType;
  final Money? price;
  final DateTime createdAt;

  /// Where the product came from; null when it isn't on a receipt.
  final ProductOrigin? origin;

  const ProductDetails({
    required this.id,
    required this.name,
    required this.productType,
    required this.expirationDate,
    required this.storageSpotType,
    required this.price,
    required this.createdAt,
    required this.origin,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    productType,
    expirationDate,
    storageSpotType,
    price,
    createdAt,
    origin,
  ];
}

/// The receipt a product was added from, and who added it where.
class ProductOrigin extends Equatable {
  final String receiptId;
  final String? creatorId;
  final String? creatorEmail;
  final String? creatorUsername;
  final String? spaceName;
  final String? storeName;

  /// A calendar day (UTC midnight).
  final DateTime? purchaseDate;

  const ProductOrigin({
    required this.receiptId,
    required this.creatorId,
    required this.creatorEmail,
    required this.creatorUsername,
    required this.spaceName,
    required this.storeName,
    required this.purchaseDate,
  });

  @override
  List<Object?> get props => [
    receiptId,
    creatorId,
    creatorEmail,
    creatorUsername,
    spaceName,
    storeName,
    purchaseDate,
  ];
}
