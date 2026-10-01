import '../../../../core/network/json_readers.dart';
import '../../domain/entities/receipt_label.dart';

class ReceiptLabelModel extends ReceiptLabel {
  const ReceiptLabelModel({
    required super.storeName,
    required super.purchaseDate,
  });

  /// Reads only `storeName` and `purchaseDate` from a shopping receipt's
  /// details.
  factory ReceiptLabelModel.fromJson(Map<String, dynamic> json) {
    return ReceiptLabelModel(
      storeName: json['storeName'] as String?,
      purchaseDate: readCalendarDay(json['purchaseDate']),
    );
  }
}
