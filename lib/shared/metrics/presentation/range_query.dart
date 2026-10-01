import '../domain/entities/date_range.dart';
import '../domain/entities/selected_range.dart';
import '../domain/utils/calendar_day.dart';

const kRangeParam = 'range';
const kFromParam = 'from';
const kToParam = 'to';

const kDefaultSelectedRange = PresetRange(RangePreset.last30);

/// Reads a range from the URL query:
/// `?range=7d|30d|90d` for a preset, `?from=YYYY-MM-DD&to=YYYY-MM-DD` for a
/// custom range. `range` wins when both are present.
///
/// Returns null when the query has no range or an invalid one (unknown
/// preset, malformed date, `from` after `to`, `to` after [today], or
/// `to − from` over [maxLengthInDays] — each endpoint has its own limit).
SelectedRange? parseRangeQuery(
  Map<String, String> query,
  DateTime today, {
  required int maxLengthInDays,
}) {
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
  if (range.lengthInDays > maxLengthInDays) return null;
  return CustomRange(range);
}

/// The URL query for [range]; the inverse of [parseRangeQuery].
Map<String, String> rangeQuery(SelectedRange range) => switch (range) {
  PresetRange(:final preset) => {kRangeParam: preset.key},
  CustomRange(:final range) => {
    kFromParam: isoDate(range.from),
    kToParam: isoDate(range.to),
  },
};
