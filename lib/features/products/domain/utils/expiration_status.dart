import '../../../../shared/metrics/domain/utils/calendar_day.dart';

enum ExpirationStatus { expired, soon, ok }

/// How many days ahead still count as "Expires soon" (today included).
const kExpiresSoonDays = 3;

/// [day] is a calendar day (UTC midnight); [today] is the browser's current
/// date and time.
ExpirationStatus expirationStatus(DateTime day, DateTime today) {
  final daysLeft = day.difference(calendarDay(today)).inDays;
  if (daysLeft < 0) return ExpirationStatus.expired;
  if (daysLeft <= kExpiresSoonDays) return ExpirationStatus.soon;
  return ExpirationStatus.ok;
}
