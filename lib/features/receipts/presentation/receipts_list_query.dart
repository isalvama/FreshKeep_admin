import 'package:equatable/equatable.dart';

import '../../../shared/metrics/domain/entities/selected_range.dart';
import '../../../shared/metrics/presentation/range_query.dart';

const kReceiptsPath = '/receipts';
const kReceiptsCreatorIdParam = 'creatorId';
const kReceiptsPageParam = 'page';

/// `GET /admin/shopping-receipts` rejects purchase ranges where `to − from`
/// exceeds this.
const kReceiptsMaxRangeLengthInDays = 100;

/// What the receipts list URL selects: a purchase range, an optional creator
/// and a 1-based page.
class ReceiptsListQuery extends Equatable {
  final SelectedRange range;

  /// Only receipts this user (`users.id`) uploaded.
  final String? creatorId;
  final int page;

  const ReceiptsListQuery({
    this.range = kDefaultSelectedRange,
    this.creatorId,
    this.page = 1,
  });

  /// A new range starts again from page 1.
  ReceiptsListQuery withRange(SelectedRange range) =>
      ReceiptsListQuery(range: range, creatorId: creatorId);

  /// A new (or no) creator starts again from page 1.
  ReceiptsListQuery withCreator(String? creatorId) =>
      ReceiptsListQuery(range: range, creatorId: creatorId);

  ReceiptsListQuery withPage(int page) =>
      ReceiptsListQuery(range: range, creatorId: creatorId, page: page);

  @override
  List<Object?> get props => [range, creatorId, page];
}

const kDefaultReceiptsListQuery = ReceiptsListQuery();

/// Reads the receipts list URL. Each invalid value is dropped on its own: a
/// missing or invalid range (over [kReceiptsMaxRangeLengthInDays], or in the
/// future) becomes the last 30 days, an id that isn't a UUID is dropped, a
/// page that isn't a positive integer becomes 1. A bad range never costs a
/// valid creator.
ReceiptsListQuery parseReceiptsListQuery(
  Map<String, String> query,
  DateTime today,
) {
  return ReceiptsListQuery(
    range:
        parseRangeQuery(
          query,
          today,
          maxLengthInDays: kReceiptsMaxRangeLengthInDays,
        ) ??
        kDefaultSelectedRange,
    creatorId: _parseUuid(query[kReceiptsCreatorIdParam]),
    page: _parsePage(query[kReceiptsPageParam]) ?? 1,
  );
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String? _parseUuid(String? value) =>
    value != null && _uuid.hasMatch(value) ? value : null;

/// Strictly a positive integer: rejects `0`, `-1`, `01`, `1.5`, `x`.
int? _parsePage(String? value) {
  if (value == null || !RegExp(r'^[1-9]\d{0,8}$').hasMatch(value)) {
    return null;
  }
  return int.parse(value);
}

/// The URL query for [query]; the inverse of [parseReceiptsListQuery]. A URL
/// whose query differs from this after parsing needs normalizing.
Map<String, String> receiptsListQueryParameters(ReceiptsListQuery query) => {
  ...rangeQuery(query.range),
  kReceiptsCreatorIdParam: ?query.creatorId,
  kReceiptsPageParam: '${query.page}',
};

/// The full list location, e.g. `/receipts?range=30d&creatorId=…&page=2`.
String receiptsListLocation(ReceiptsListQuery query) => Uri(
  path: kReceiptsPath,
  queryParameters: receiptsListQueryParameters(query),
).toString();
