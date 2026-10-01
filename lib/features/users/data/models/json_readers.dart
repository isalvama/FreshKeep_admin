import '../../../../shared/metrics/domain/utils/calendar_day.dart';

/// An ISO-8601 instant such as `2026-01-10T10:00:00Z` (how the backend
/// serializes `Instant`), as UTC. Throws [FormatException] otherwise.
DateTime readInstant(Object? value) {
  if (value is! String) {
    throw FormatException('Expected an ISO-8601 instant, got $value');
  }
  return DateTime.parse(value).toUtc();
}

DateTime? readOptionalInstant(Object? value) =>
    value == null ? null : readInstant(value);

/// A `yyyy-MM-dd` calendar day. Throws [FormatException] otherwise.
DateTime readCalendarDay(Object? value) {
  final day = tryParseIsoDate(value is String ? value : null);
  if (day == null) throw FormatException('Expected yyyy-MM-dd, got $value');
  return day;
}
