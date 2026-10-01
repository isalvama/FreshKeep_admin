import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/utils/calendar_day.dart';

void main() {
  test('isoDate formats yyyy-MM-dd with zero padding', () {
    expect(isoDate(DateTime.utc(2026, 9, 1)), '2026-09-01');
  });

  test('tryParseIsoDate parses strict yyyy-MM-dd', () {
    expect(tryParseIsoDate('2026-09-01'), DateTime.utc(2026, 9, 1));
  });

  test('tryParseIsoDate rejects other formats and impossible dates', () {
    for (final value in [
      null,
      '',
      '2026-9-1',
      '01-09-2026',
      '2026-09-01T00:00:00',
      '2026-02-30',
      '2026-13-01',
      'yesterday',
    ]) {
      expect(tryParseIsoDate(value), isNull, reason: '$value');
    }
  });
}
