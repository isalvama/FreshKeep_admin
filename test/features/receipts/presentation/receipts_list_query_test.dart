import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/receipts_list_location.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/receipts_list_query.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/date_range.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/selected_range.dart';

final _today = DateTime(2026, 10, 1, 9);
const _creator = '3f2a9c1e-0b4d-4e8a-9f61-2c7d5e8b1a04';

ReceiptsListQuery _parse(Map<String, String> query) =>
    parseReceiptsListQuery(query, _today);

void main() {
  group('parseReceiptsListQuery', () {
    test('reads a preset, a creator and a page', () {
      expect(
        _parse({'range': '7d', 'creatorId': _creator, 'page': '2'}),
        const ReceiptsListQuery(
          range: PresetRange(RangePreset.last7),
          creatorId: _creator,
          page: 2,
        ),
      );
    });

    test('reads a custom range', () {
      expect(
        _parse({'from': '2026-09-01', 'to': '2026-09-15', 'page': '1'}).range,
        CustomRange(
          DateRange(
            from: DateTime.utc(2026, 9, 1),
            to: DateTime.utc(2026, 9, 15),
          ),
        ),
      );
    });

    test('an empty query is the default: last 30 days, page 1', () {
      expect(_parse({}), kDefaultReceiptsListQuery);
      expect(
        kDefaultReceiptsListQuery,
        const ReceiptsListQuery(
          range: PresetRange(RangePreset.last30),
          page: 1,
        ),
      );
    });

    test('accepts 100 days (to − from) and falls back past it', () {
      // Jun 23 → Oct 1 is 100 days; Jun 22 → Oct 1 is 101.
      expect(
        _parse({'from': '2026-06-23', 'to': '2026-10-01'}).range,
        isA<CustomRange>(),
      );
      expect(
        _parse({'from': '2026-06-22', 'to': '2026-10-01'}).range,
        kDefaultReceiptsListQuery.range,
      );
    });

    test('a bad range becomes 30 days, keeping the creator and page', () {
      for (final range in [
        {'range': '14d'},
        {'from': '2026-09-15', 'to': '2026-09-01'},
        {'from': '2026-09-01', 'to': '2026-10-02'}, // ends after today
        {'from': 'yesterday', 'to': '2026-10-01'},
      ]) {
        final query = _parse({...range, 'creatorId': _creator, 'page': '3'});
        expect(query.range, kDefaultReceiptsListQuery.range, reason: '$range');
        expect(query.creatorId, _creator);
        expect(query.page, 3);
      }
    });

    test('a creator id that is not a UUID is dropped, keeping the rest', () {
      for (final id in ['abc', '../users', '${_creator}0']) {
        final query = _parse({'range': '7d', 'creatorId': id, 'page': '2'});
        expect(query.creatorId, isNull, reason: id);
        expect(query.range, const PresetRange(RangePreset.last7));
        expect(query.page, 2);
      }
    });

    test(
      'a page that is not a positive integer becomes 1, keeping the rest',
      () {
        for (final page in ['0', '-1', '01', '1.5', 'x', '1234567890']) {
          final query = _parse({
            'range': '90d',
            'creatorId': _creator,
            'page': page,
          });
          expect(query.page, 1, reason: page);
          expect(query.range, const PresetRange(RangePreset.last90));
          expect(query.creatorId, _creator);
        }
      },
    );
  });

  group('receiptsListQueryParameters', () {
    test('writes the range and page, and the creator only when set', () {
      expect(receiptsListQueryParameters(kDefaultReceiptsListQuery), {
        'range': '30d',
        'page': '1',
      });
    });

    test('round-trips through parseReceiptsListQuery', () {
      final query = ReceiptsListQuery(
        range: CustomRange(
          DateRange(
            from: DateTime.utc(2026, 9, 1),
            to: DateTime.utc(2026, 9, 30),
          ),
        ),
        creatorId: _creator,
        page: 4,
      );
      expect(_parse(receiptsListQueryParameters(query)), query);
    });

    test('receiptsListLocation builds the full URL', () {
      expect(
        receiptsListLocation(
          const ReceiptsListQuery(creatorId: _creator, page: 2),
        ),
        '/receipts?range=30d&creatorId=$_creator&page=2',
      );
    });
  });

  group('ReceiptsListQuery', () {
    test('a new range or creator resets the page; withPage keeps the rest', () {
      const query = ReceiptsListQuery(creatorId: _creator, page: 5);

      expect(
        query.withRange(const PresetRange(RangePreset.last7)),
        const ReceiptsListQuery(
          range: PresetRange(RangePreset.last7),
          creatorId: _creator,
        ),
      );
      expect(query.withCreator(null), const ReceiptsListQuery());
      expect(
        query.withPage(6),
        const ReceiptsListQuery(creatorId: _creator, page: 6),
      );
    });
  });

  group('ReceiptsListLocation', () {
    test('starts at the default list URL', () {
      expect(ReceiptsListLocation().value, '/receipts?range=30d&page=1');
    });

    test('remembers list URLs and ignores anything else', () {
      final location = ReceiptsListLocation()
        ..remember('/receipts?range=7d&page=3')
        ..remember('/receipts/$_creator')
        ..remember('/products?sort=name_asc&page=1');

      expect(location.value, '/receipts?range=7d&page=3');
    });
  });
}
