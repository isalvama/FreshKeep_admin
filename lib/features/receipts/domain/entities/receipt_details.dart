import 'package:equatable/equatable.dart';

import '../../../../shared/products/money.dart';

class ReceiptDetails extends Equatable {
  final String id;

  /// Null when the creator no longer exists.
  final String? creatorId;
  final String? creatorEmail;
  final String? creatorUsername;

  /// Null when the space no longer exists.
  final String? spaceName;
  final String? storeName;

  /// A calendar day (UTC midnight).
  final DateTime purchaseDate;

  /// When it was uploaded.
  final DateTime createdAt;

  /// The image's MIME type, e.g. `image/jpeg`; null when there is no image.
  final String? imageMimeType;

  /// Oldest first, deleted ones included (flagged).
  final List<ReceiptProduct> products;

  const ReceiptDetails({
    required this.id,
    required this.creatorId,
    required this.creatorEmail,
    required this.creatorUsername,
    required this.spaceName,
    required this.storeName,
    required this.purchaseDate,
    required this.createdAt,
    required this.imageMimeType,
    required this.products,
  });

  @override
  List<Object?> get props => [
    id,
    creatorId,
    creatorEmail,
    creatorUsername,
    spaceName,
    storeName,
    purchaseDate,
    createdAt,
    imageMimeType,
    products,
  ];
}

class ReceiptProduct extends Equatable {
  final String id;
  final String name;

  /// Raw backend value, e.g. `DAIRY`.
  final String productType;

  /// A calendar day (UTC midnight).
  final DateTime? expirationDate;
  final Money? price;

  /// Removed from its space; it no longer has a product page.
  final bool deleted;

  const ReceiptProduct({
    required this.id,
    required this.name,
    required this.productType,
    required this.expirationDate,
    required this.price,
    required this.deleted,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    productType,
    expirationDate,
    price,
    deleted,
  ];
}
