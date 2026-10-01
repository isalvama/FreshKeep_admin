/// Calendar days are represented as UTC midnight of that day, regardless of
/// the browser's timezone. Local midnights would make day arithmetic wrong
/// across daylight-saving changes (a 23- or 25-hour "day").
DateTime calendarDay(DateTime dateTime) =>
    DateTime.utc(dateTime.year, dateTime.month, dateTime.day);

/// `yyyy-MM-dd`, the format the backend's `from`/`to` parameters and JSON
/// dates use.
String isoDate(DateTime day) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Parses a strict `yyyy-MM-dd` into a calendar day, or null. Rejects
/// impossible dates such as `2026-02-30` (which [DateTime] would roll over).
DateTime? tryParseIsoDate(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final day = DateTime.utc(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
  return isoDate(day) == value ? day : null;
}
