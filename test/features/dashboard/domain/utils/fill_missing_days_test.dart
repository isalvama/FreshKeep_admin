import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/daily_count.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/date_range.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/utils/fill_missing_days.dart';

DateTime _day(int d) => DateTime.utc(2026, 9, d);
DailyCount _count(int d, int count) => DailyCount(date: _day(d), count: count);

void main() {
  final range = DateRange(from: _day(1), to: _day(5));

  test('fills days the backend omitted with 0, in order', () {
    expect(fillMissingDays([_count(4, 3), _count(2, 1)], range), [
      _count(1, 0),
      _count(2, 1),
      _count(3, 0),
      _count(4, 3),
      _count(5, 0),
    ]);
  });

  test('an empty response becomes all zeros', () {
    final filled = fillMissingDays([], range);

    expect(filled, hasLength(5));
    expect(filled.every((c) => c.count == 0), isTrue);
  });

  test('drops entries outside the range', () {
    final filled = fillMissingDays([_count(9, 7), _count(1, 2)], range);

    expect(filled.map((c) => c.count), [2, 0, 0, 0, 0]);
  });

  test('sums duplicate dates', () {
    final filled = fillMissingDays([_count(2, 1), _count(2, 4)], range);

    expect(filled[1], _count(2, 5));
  });
}
