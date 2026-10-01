import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/dashboard_range.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/date_range.dart';
import 'package:fresh_keep_admin/features/dashboard/presentation/dashboard_query.dart';

final _today = DateTime(2026, 10, 1, 14, 30);

DashboardRange? _parse(Map<String, String> query) =>
    parseDashboardRange(query, _today);

CustomRange _custom(String from, String to) =>
    CustomRange(DateRange(from: DateTime.parse(from), to: DateTime.parse(to)));

void main() {
  group('parseDashboardRange', () {
    test('reads each preset', () {
      expect(_parse({'range': '7d'}), const PresetRange(RangePreset.last7));
      expect(_parse({'range': '30d'}), const PresetRange(RangePreset.last30));
      expect(_parse({'range': '90d'}), const PresetRange(RangePreset.last90));
    });

    test('reads a valid custom range', () {
      expect(
        _parse({'from': '2026-09-01', 'to': '2026-09-15'}),
        _custom('2026-09-01', '2026-09-15'),
      );
    });

    test('accepts a custom range ending today and a single day', () {
      expect(_parse({'from': '2026-09-01', 'to': '2026-10-01'}), isNotNull);
      expect(_parse({'from': '2026-10-01', 'to': '2026-10-01'}), isNotNull);
    });

    test('accepts exactly 100 days (to − from) and rejects 101', () {
      expect(_parse({'from': '2026-06-23', 'to': '2026-10-01'}), isNotNull);
      expect(_parse({'from': '2026-06-22', 'to': '2026-10-01'}), isNull);
    });

    test('prefers range when both forms are present', () {
      expect(
        _parse({'range': '7d', 'from': '2026-09-01', 'to': '2026-09-15'}),
        const PresetRange(RangePreset.last7),
      );
    });

    test('returns null for a missing or invalid range', () {
      for (final query in <Map<String, String>>[
        {},
        {'range': '14d'},
        {'range': ''},
        // An unknown preset is not rescued by a valid from/to.
        {'range': 'bad', 'from': '2026-09-01', 'to': '2026-09-15'},
        {'from': '2026-09-01'},
        {'to': '2026-09-15'},
        {'from': '2026-9-1', 'to': '2026-09-15'},
        {'from': '2026-02-30', 'to': '2026-03-15'},
        {'from': '2026-09-15', 'to': '2026-09-01'},
        {'from': '2026-09-15', 'to': '2026-10-02'},
      ]) {
        expect(_parse(query), isNull, reason: '$query');
      }
    });
  });

  group('dashboardRangeQuery', () {
    test('writes presets as range', () {
      expect(dashboardRangeQuery(const PresetRange(RangePreset.last90)), {
        'range': '90d',
      });
    });

    test('writes custom ranges as from/to', () {
      expect(dashboardRangeQuery(_custom('2026-09-01', '2026-09-15')), {
        'from': '2026-09-01',
        'to': '2026-09-15',
      });
    });

    test('round-trips through parseDashboardRange', () {
      for (final range in [
        ...RangePreset.values.map(PresetRange.new),
        _custom('2026-09-01', '2026-09-15'),
      ]) {
        expect(_parse(dashboardRangeQuery(range)), range, reason: '$range');
      }
    });
  });

  test('the default range is the last 30 days', () {
    expect(kDefaultDashboardRange, const PresetRange(RangePreset.last30));
  });
}
