import '../../domain/entities/daily_count.dart';
import '../../domain/utils/calendar_day.dart';

class DailyCountModel extends DailyCount {
  DailyCountModel({required super.date, required super.count});

  /// `{"date": "2026-09-14", "count": 3}`. The receipts metric names its
  /// count `totalReceipts`, so the key is configurable.
  factory DailyCountModel.fromJson(
    Map<String, dynamic> json, {
    String countKey = 'count',
  }) {
    final date = tryParseIsoDate(json['date'] as String?);
    if (date == null) {
      throw FormatException('Invalid metric date: ${json['date']}');
    }
    return DailyCountModel(date: date, count: (json[countKey] as num).toInt());
  }
}
