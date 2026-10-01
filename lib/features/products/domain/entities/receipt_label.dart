import 'package:equatable/equatable.dart';

/// What the receipt filter chip shows: "SuperMart · Sep 8, 2026".
class ReceiptLabel extends Equatable {
  final String? storeName;

  /// A calendar day (UTC midnight).
  final DateTime purchaseDate;

  const ReceiptLabel({required this.storeName, required this.purchaseDate});

  @override
  List<Object?> get props => [storeName, purchaseDate];
}
