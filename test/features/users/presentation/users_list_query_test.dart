import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/users/presentation/users_list_location.dart';
import 'package:fresh_keep_admin/features/users/presentation/users_list_query.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/date_range.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/selected_range.dart';

final _today = DateTime(2026, 10, 1, 9);

UsersListQuery? _parse(Map<String, String> query) =>
    parseUsersListQuery(query, _today);

void main() {
  group('parseUsersListQuery', () {
    test('reads a preset range and a page', () {
      expect(
        _parse({'range': '7d', 'page': '2'}),
        const UsersListQuery(range: PresetRange(RangePreset.last7), page: 2),
      );
    });

    test('reads a custom range and a page', () {
      expect(
        _parse({'from': '2026-09-01', 'to': '2026-09-15', 'page': '1'}),
        UsersListQuery(
          range: CustomRange(
            DateRange(from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 15)),
          ),
          page: 1,
        ),
      );
    });

    test('accepts 90 days (to − from) and rejects 91', () {
      expect(
        _parse({'from': '2026-07-03', 'to': '2026-10-01', 'page': '1'}),
        isNotNull,
      );
      expect(
        _parse({'from': '2026-07-02', 'to': '2026-10-01', 'page': '1'}),
        isNull,
      );
    });

    test('rejects a missing or non-positive-integer page', () {
      for (final page in [null, '0', '-1', 'x', '1.5', '01', '', ' 2']) {
        expect(
          _parse({'range': '30d', 'page': ?page}),
          isNull,
          reason: 'page=$page',
        );
      }
    });

    test('rejects a missing or invalid range', () {
      expect(_parse({'page': '1'}), isNull);
      expect(_parse({'range': '14d', 'page': '1'}), isNull);
    });
  });

  test('usersListQueryParameters round-trips through the parser', () {
    for (final query in [
      kDefaultUsersListQuery,
      const UsersListQuery(range: PresetRange(RangePreset.last90), page: 8),
      UsersListQuery(
        range: CustomRange(
          DateRange(from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 15)),
        ),
        page: 3,
      ),
    ]) {
      expect(_parse(usersListQueryParameters(query)), query, reason: '$query');
    }
  });

  test('the default is the last 30 days, page 1', () {
    expect(
      usersListLocation(kDefaultUsersListQuery),
      '/users?range=30d&page=1',
    );
  });

  group('UsersListLocation', () {
    test('starts at the default list URL', () {
      expect(UsersListLocation().value, '/users?range=30d&page=1');
    });

    test('remembers the last list URL', () {
      final location = UsersListLocation()
        ..remember('/users?range=7d&page=3')
        ..remember('/users?from=2026-09-01&to=2026-09-15&page=2');

      expect(location.value, '/users?from=2026-09-01&to=2026-09-15&page=2');
    });

    test('ignores locations that are not the list', () {
      final location = UsersListLocation()
        ..remember('/users?range=7d&page=3')
        ..remember('/users/u-1')
        ..remember('/dashboard?range=30d');

      expect(location.value, '/users?range=7d&page=3');
    });
  });
}
