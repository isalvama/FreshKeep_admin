import '../domain/entities/dashboard_range.dart';
import '../domain/entities/date_range.dart';
import '../domain/utils/calendar_day.dart';

const kRangeParam = 'range';
const kFromParam = 'from';
const kToParam = 'to';

const kDefaultDashboardRange = PresetRange(RangePreset.last30);

/// Reads the dashboard range from the URL query:
/// `?range=7d|30d|90d` for a preset, `?from=YYYY-MM-DD&to=YYYY-MM-DD` for a
/// custom range. `range` wins when both are present.
///
/// Returns null when the query has no range or an invalid one (unknown
/// preset, malformed date, `from` after `to`, `to` after [today], or longer
/// than [kMaxRangeLengthInDays]); the page then falls back to
/// [kDefaultDashboardRange].
DashboardRange? parseDashboardRange(Map<String, String> query, DateTime today) {
  final presetKey = query[kRangeParam];
  if (presetKey != null) {
    for (final preset in RangePreset.values) {
      if (preset.key == presetKey) return PresetRange(preset);
    }
    return null;
  }

  final from = tryParseIsoDate(query[kFromParam]);
  final to = tryParseIsoDate(query[kToParam]);
  if (from == null || to == null) return null;
  if (from.isAfter(to) || to.isAfter(calendarDay(today))) return null;

  final range = DateRange(from: from, to: to);
  if (range.lengthInDays > kMaxRangeLengthInDays) return null;
  return CustomRange(range);
}

/// The URL query for [range]; the inverse of [parseDashboardRange].
Map<String, String> dashboardRangeQuery(DashboardRange range) =>
    switch (range) {
      PresetRange(:final preset) => {kRangeParam: preset.key},
      CustomRange(:final range) => {
        kFromParam: isoDate(range.from),
        kToParam: isoDate(range.to),
      },
    };
