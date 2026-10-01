import 'package:dio/dio.dart';

import '../../../../core/network/admin_api_paths.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../../../../shared/metrics/domain/utils/calendar_day.dart';
import '../../domain/repositories/receipts_repository.dart';
import '../models/receipt_details_model.dart';
import '../models/receipts_page_model.dart';

class ReceiptsRemoteDataSource {
  final Dio dio;

  const ReceiptsRemoteDataSource(this.dio);

  Future<ReceiptsPageModel> getReceipts(
    DateRange purchasedBetween, {
    String? creatorId,
    required int page,
  }) async {
    final response = await dio.get(
      kAdminShoppingReceiptsApiPath,
      queryParameters: {
        'from': isoDate(purchasedBetween.from),
        'to': isoDate(purchasedBetween.to),
        'userId': ?creatorId,
        'page': page,
        'size': kReceiptsPageSize,
      },
    );
    return ReceiptsPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReceiptDetailsModel> getReceipt(String receiptId) async {
    // The id comes from the URL bar: encode it so it can only ever be one
    // path segment.
    final response = await dio.get(
      '$kAdminShoppingReceiptsApiPath/${Uri.encodeComponent(receiptId)}',
    );
    return ReceiptDetailsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
