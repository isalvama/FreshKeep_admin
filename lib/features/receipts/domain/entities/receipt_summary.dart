import 'package:equatable/equatable.dart';

/// One row of the receipts list.
class ReceiptSummary extends Equatable {
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

  /// Products on the receipt, excluding deleted ones.
  final int productCount;

  const ReceiptSummary({
    required this.id,
    required this.creatorId,
    required this.creatorEmail,
    required this.creatorUsername,
    required this.spaceName,
    required this.storeName,
    required this.purchaseDate,
    required this.productCount,
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
    productCount,
  ];
}
