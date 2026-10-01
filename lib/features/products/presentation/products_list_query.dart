import 'package:equatable/equatable.dart';

import '../../../shared/products/product_type.dart';
import '../domain/entities/product_filters.dart';
import '../domain/entities/product_sort.dart';

const kProductsPath = '/products';
const kSortParam = 'sort';
const kTypeParam = 'type';
const kCreatorIdParam = 'creatorId';
const kReceiptIdParam = 'receiptId';
const kProductsPageParam = 'page';

/// What the products list URL selects: an order, optional filters and a
/// 1-based page.
class ProductsListQuery extends Equatable {
  final ProductFilters filters;
  final int page;

  const ProductsListQuery({
    this.filters = const ProductFilters(),
    this.page = 1,
  });

  /// New sort or filters always start again from page 1.
  ProductsListQuery withFilters(ProductFilters filters) =>
      ProductsListQuery(filters: filters);

  ProductsListQuery withPage(int page) =>
      ProductsListQuery(filters: filters, page: page);

  @override
  List<Object?> get props => [filters, page];
}

const kDefaultProductsListQuery = ProductsListQuery();

/// Reads the products list URL. Each invalid value is dropped on its own (an
/// unknown sort or type, an id that isn't a UUID, a page that isn't a
/// positive integer), so a bad `page` never costs a valid filter.
ProductsListQuery parseProductsListQuery(Map<String, String> query) {
  final type = query[kTypeParam];
  return ProductsListQuery(
    filters: ProductFilters(
      sort: ProductSort.fromUrlValue(query[kSortParam]) ?? ProductSort.nameAsc,
      productType: kProductTypes.contains(type) ? type : null,
      creatorId: _parseUuid(query[kCreatorIdParam]),
      receiptId: _parseUuid(query[kReceiptIdParam]),
    ),
    page: _parsePage(query[kProductsPageParam]) ?? 1,
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

/// The URL query for [query]; the inverse of [parseProductsListQuery]. A URL
/// whose query differs from this after parsing needs normalizing.
Map<String, String> productsListQueryParameters(ProductsListQuery query) {
  final filters = query.filters;
  return {
    kSortParam: filters.sort.urlValue,
    kTypeParam: ?filters.productType,
    kCreatorIdParam: ?filters.creatorId,
    kReceiptIdParam: ?filters.receiptId,
    kProductsPageParam: '${query.page}',
  };
}

/// The full list location, e.g. `/products?sort=name_asc&type=DAIRY&page=2`.
String productsListLocation(ProductsListQuery query) => Uri(
  path: kProductsPath,
  queryParameters: productsListQueryParameters(query),
).toString();
