import '../../../../core/network/json_readers.dart';
import '../../domain/entities/receipt_summary.dart';
import '../../domain/entities/receipts_page.dart';

class ReceiptSummaryModel extends ReceiptSummary {
  const ReceiptSummaryModel({
    required super.id,
    required super.creatorId,
    required super.creatorEmail,
    required super.creatorUsername,
    required super.spaceName,
    required super.storeName,
    required super.purchaseDate,
    required super.productCount,
  });

  /// `{id, creatorId, creatorEmail, creatorUsername, spaceId, spaceName,
  /// storeName, purchaseDate, createdAt, productCount}`.
  factory ReceiptSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReceiptSummaryModel(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String?,
      creatorEmail: json['creatorEmail'] as String?,
      creatorUsername: json['creatorUsername'] as String?,
      spaceName: json['spaceName'] as String?,
      storeName: json['storeName'] as String?,
      purchaseDate: readCalendarDay(json['purchaseDate']),
      productCount: (json['productCount'] as num).toInt(),
    );
  }
}

class ReceiptsPageModel extends ReceiptsPage {
  const ReceiptsPageModel({
    required super.receipts,
    required super.page,
    required super.size,
    required super.totalElements,
    required super.totalPages,
  });

  /// `{content, page, size, totalElements, totalPages}`.
  factory ReceiptsPageModel.fromJson(Map<String, dynamic> json) {
    return ReceiptsPageModel(
      receipts: [
        for (final receipt in json['content'] as List)
          ReceiptSummaryModel.fromJson(receipt as Map<String, dynamic>),
      ],
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      totalElements: (json['totalElements'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );
  }
}
