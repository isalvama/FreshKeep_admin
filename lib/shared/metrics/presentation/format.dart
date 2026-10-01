const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `Sep 14` — axis labels and tooltips, where the year is implied.
String formatShortDate(DateTime day) => '${_months[day.month - 1]} ${day.day}';

/// `Sep 14, 2026` — table rows and range labels.
String formatDate(DateTime day) => '${formatShortDate(day)}, ${day.year}';

/// `1,234,567`.
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// `Sep 14, 2026, 14:32` — an instant (e.g. a backend UTC timestamp) in the
/// browser's local time.
String formatDateTime(DateTime instant) {
  final local = instant.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${formatDate(local)}, $hh:$mm';
}
