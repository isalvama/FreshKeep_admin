import '../entities/daily_count.dart';
import '../entities/date_range.dart';

/// The backend only returns days with activity. Returns one entry per day of
/// [range], in order, with 0 for missing days. Entries outside [range] are
/// dropped; duplicate dates are summed.
List<DailyCount> fillMissingDays(List<DailyCount> counts, DateRange range) {
  final byDay = <DateTime, int>{};
  for (final entry in counts) {
    byDay.update(
      entry.date,
      (sum) => sum + entry.count,
      ifAbsent: () => entry.count,
    );
  }
  return [
    for (final day in range.days) DailyCount(date: day, count: byDay[day] ?? 0),
  ];
}
