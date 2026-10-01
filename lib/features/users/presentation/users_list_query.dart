import 'package:equatable/equatable.dart';

import '../../../shared/metrics/domain/entities/selected_range.dart';
import '../../../shared/metrics/presentation/range_query.dart';

const kUsersPath = '/users';
const kPageParam = 'page';

/// `GET /admin/users` rejects registration ranges where `to − from` exceeds
/// this (the metrics endpoints allow 100).
const kUsersMaxRangeLengthInDays = 90;

/// What the users list URL selects: a registration range and a 1-based page.
class UsersListQuery extends Equatable {
  final SelectedRange range;
  final int page;

  const UsersListQuery({required this.range, required this.page});

  @override
  List<Object?> get props => [range, page];
}

const kDefaultUsersListQuery = UsersListQuery(
  range: kDefaultSelectedRange,
  page: 1,
);

/// Reads `?range=…` (or `from`/`to`) and `page` from the users list URL.
///
/// Returns null — and the page falls back to [kDefaultUsersListQuery] — when
/// the range is missing or invalid (over [kUsersMaxRangeLengthInDays]), or
/// when `page` is missing or not a positive integer.
UsersListQuery? parseUsersListQuery(Map<String, String> query, DateTime today) {
  final range = parseRangeQuery(
    query,
    today,
    maxLengthInDays: kUsersMaxRangeLengthInDays,
  );
  final page = _parsePage(query[kPageParam]);
  if (range == null || page == null) return null;
  return UsersListQuery(range: range, page: page);
}

/// Strictly a positive integer: rejects `0`, `-1`, `01`, `1.5`, `x`.
int? _parsePage(String? value) {
  if (value == null || !RegExp(r'^[1-9]\d{0,8}$').hasMatch(value)) {
    return null;
  }
  return int.parse(value);
}

/// The URL query for [query]; the inverse of [parseUsersListQuery].
Map<String, String> usersListQueryParameters(UsersListQuery query) => {
  ...rangeQuery(query.range),
  kPageParam: '${query.page}',
};

/// The full list location, e.g. `/users?range=30d&page=2`.
String usersListLocation(UsersListQuery query) => Uri(
  path: kUsersPath,
  queryParameters: usersListQueryParameters(query),
).toString();
