import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/selected_range.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/date_range.dart';

DateTime _day(int y, int m, int d) => DateTime.utc(y, m, d);

void main() {
  group('DateRange', () {
    test('normalizes to calendar days, dropping the time of day', () {
      final range = DateRange(
        from: DateTime(2026, 9, 1, 23, 59),
        to: DateTime(2026, 9, 3, 0, 1),
      );

      expect(range.from, _day(2026, 9, 1));
      expect(range.to, _day(2026, 9, 3));
    });

    test('lengthInDays is to − from, and days lists every day inclusive', () {
      final range = DateRange(from: _day(2026, 9, 1), to: _day(2026, 9, 3));

      expect(range.lengthInDays, 2);
      expect(range.days, [
        _day(2026, 9, 1),
        _day(2026, 9, 2),
        _day(2026, 9, 3),
      ]);
    });

    test('a single-day range has one day', () {
      final range = DateRange(from: _day(2026, 9, 1), to: _day(2026, 9, 1));

      expect(range.lengthInDays, 0);
      expect(range.days, [_day(2026, 9, 1)]);
    });

    test('day arithmetic is not shifted by daylight-saving changes', () {
      // Europe and the US change clocks in late March / early November.
      final range = DateRange(from: _day(2026, 3, 25), to: _day(2026, 4, 2));

      expect(range.lengthInDays, 8);
      expect(range.days, hasLength(9));
      expect(range.days.toSet(), hasLength(9));
    });
  });

  group('PresetRange.resolve', () {
    test('ends today and covers the preset number of days', () {
      for (final preset in RangePreset.values) {
        final range = PresetRange(preset).resolve(DateTime(2026, 10, 1, 15));

        expect(range.to, _day(2026, 10, 1), reason: preset.key);
        expect(range.days, hasLength(preset.days), reason: preset.key);
      }
    });

    test('crosses month boundaries', () {
      final range = const PresetRange(
        RangePreset.last7,
      ).resolve(DateTime(2026, 3, 3));

      expect(range.from, _day(2026, 2, 25));
    });

    test('crosses year boundaries', () {
      final range = const PresetRange(
        RangePreset.last30,
      ).resolve(DateTime(2026, 1, 10));

      expect(range.from, _day(2025, 12, 12));
    });

    test('presets have their URL keys and labels', () {
      expect(RangePreset.values.map((p) => p.key), ['7d', '30d', '90d']);
      expect(RangePreset.last30.label, 'Last 30 days');
    });
  });

  test('CustomRange.resolve returns its range regardless of today', () {
    final range = DateRange(from: _day(2026, 9, 1), to: _day(2026, 9, 15));

    expect(CustomRange(range).resolve(DateTime(2030)), range);
  });
}
