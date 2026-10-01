import 'package:equatable/equatable.dart';

import '../utils/calendar_day.dart';
import 'date_range.dart';

enum RangePreset {
  last7('7d', 7),
  last30('30d', 30),
  last90('90d', 90);

  /// The `?range=` value in the URL.
  final String key;

  /// Number of days covered, today included.
  final int days;

  const RangePreset(this.key, this.days);

  String get label => 'Last $days days';
}

/// The range the admin picked. Presets are relative to today, so a shared
/// "last 30 days" link stays current.
sealed class DashboardRange extends Equatable {
  const DashboardRange();

  DateRange resolve(DateTime today);
}

class PresetRange extends DashboardRange {
  final RangePreset preset;

  const PresetRange(this.preset);

  /// Ends today; covers [RangePreset.days] days.
  @override
  DateRange resolve(DateTime today) {
    final to = calendarDay(today);
    return DateRange(
      from: DateTime.utc(to.year, to.month, to.day - (preset.days - 1)),
      to: to,
    );
  }

  @override
  List<Object?> get props => [preset];
}

class CustomRange extends DashboardRange {
  final DateRange range;

  const CustomRange(this.range);

  @override
  DateRange resolve(DateTime today) => range;

  @override
  List<Object?> get props => [range];
}
