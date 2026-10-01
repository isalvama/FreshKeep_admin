import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/shared/products/expiration_status.dart';

void main() {
  // Late evening local time: only the date part may count.
  final today = DateTime(2026, 9, 10, 23, 30);
  ExpirationStatus statusOf(int year, int month, int day) =>
      expirationStatus(DateTime.utc(year, month, day), today);

  test('yesterday is expired', () {
    expect(statusOf(2026, 9, 9), ExpirationStatus.expired);
  });

  test('today through 3 days ahead expire soon', () {
    expect(statusOf(2026, 9, 10), ExpirationStatus.soon);
    expect(statusOf(2026, 9, 13), ExpirationStatus.soon);
  });

  test('4 days ahead is fine', () {
    expect(statusOf(2026, 9, 14), ExpirationStatus.ok);
  });

  test('counts calendar days across month ends', () {
    expect(
      expirationStatus(DateTime.utc(2026, 10, 2), DateTime(2026, 9, 30)),
      ExpirationStatus.soon,
    );
    expect(
      expirationStatus(DateTime.utc(2026, 10, 4), DateTime(2026, 9, 30)),
      ExpirationStatus.ok,
    );
  });
}
