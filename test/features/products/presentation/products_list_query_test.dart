import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_filters.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_sort.dart';
import 'package:fresh_keep_admin/features/products/presentation/products_list_location.dart';
import 'package:fresh_keep_admin/features/products/presentation/products_list_query.dart';

const _creator = '3f2a9c1e-0b4d-4e8a-9f61-2c7d5e8b1a04';
const _receipt = 'D5B3E9C2-1111-4222-8333-944455556666';

void main() {
  group('parseProductsListQuery', () {
    test('reads every parameter', () {
      expect(
        parseProductsListQuery({
          'sort': 'price_desc',
          'type': 'DAIRY',
          'creatorId': _creator,
          'receiptId': _receipt,
          'page': '3',
        }),
        const ProductsListQuery(
          filters: ProductFilters(
            sort: ProductSort.priceDesc,
            productType: 'DAIRY',
            creatorId: _creator,
            receiptId: _receipt,
          ),
          page: 3,
        ),
      );
    });

    test('an empty query is the default: name A–Z, page 1', () {
      expect(parseProductsListQuery({}), kDefaultProductsListQuery);
      expect(
        kDefaultProductsListQuery,
        const ProductsListQuery(
          filters: ProductFilters(sort: ProductSort.nameAsc),
          page: 1,
        ),
      );
    });

    test('an unknown sort falls back to name A–Z, keeping the rest', () {
      for (final sort in ['NAME_ASC', 'name', 'price', '']) {
        final query = parseProductsListQuery({
          'sort': sort,
          'type': 'DAIRY',
          'page': '2',
        });
        expect(query.filters.sort, ProductSort.nameAsc, reason: sort);
        expect(query.filters.productType, 'DAIRY');
        expect(query.page, 2);
      }
    });

    test('an unknown type is dropped, keeping the rest', () {
      for (final type in ['dairy', 'CHEESE', '']) {
        final query = parseProductsListQuery({
          'type': type,
          'creatorId': _creator,
        });
        expect(query.filters.productType, isNull, reason: type);
        expect(query.filters.creatorId, _creator);
      }
    });

    test('ids that are not UUIDs are dropped, keeping the rest', () {
      for (final id in ['abc', '../users', '$_creator/x', '${_creator}0']) {
        final query = parseProductsListQuery({
          'creatorId': id,
          'receiptId': id,
          'type': 'BAKERY',
        });
        expect(query.filters.creatorId, isNull, reason: id);
        expect(query.filters.receiptId, isNull, reason: id);
        expect(query.filters.productType, 'BAKERY');
      }
    });

    test(
      'a page that is not a positive integer becomes 1, keeping filters',
      () {
        for (final page in ['0', '-1', '01', '1.5', 'x', '', '1234567890']) {
          final query = parseProductsListQuery({
            'page': page,
            'creatorId': _creator,
          });
          expect(query.page, 1, reason: page);
          expect(query.filters.creatorId, _creator);
        }
      },
    );
  });

  group('productsListQueryParameters', () {
    test('writes only what is set, with the page always present', () {
      expect(productsListQueryParameters(kDefaultProductsListQuery), {
        'sort': 'name_asc',
        'page': '1',
      });
    });

    test('round-trips through parseProductsListQuery', () {
      const query = ProductsListQuery(
        filters: ProductFilters(
          sort: ProductSort.expirationDesc,
          productType: 'ICE_CREAM_AND_DESSERTS',
          creatorId: _creator,
          receiptId: _receipt,
        ),
        page: 7,
      );
      expect(parseProductsListQuery(productsListQueryParameters(query)), query);
    });

    test('productsListLocation builds the full URL', () {
      expect(
        productsListLocation(
          const ProductsListQuery(
            filters: ProductFilters(productType: 'DAIRY'),
            page: 2,
          ),
        ),
        '/products?sort=name_asc&type=DAIRY&page=2',
      );
    });
  });

  group('ProductsListQuery', () {
    test('new filters reset the page to 1; withPage keeps the filters', () {
      const query = ProductsListQuery(
        filters: ProductFilters(productType: 'DAIRY'),
        page: 4,
      );

      expect(
        query.withFilters(const ProductFilters(sort: ProductSort.priceAsc)),
        const ProductsListQuery(
          filters: ProductFilters(sort: ProductSort.priceAsc),
          page: 1,
        ),
      );
      expect(query.withPage(5).filters, query.filters);
      expect(query.withPage(5).page, 5);
    });
  });

  group('ProductsListLocation', () {
    test('starts at the default list URL', () {
      expect(ProductsListLocation().value, '/products?sort=name_asc&page=1');
    });

    test('remembers list URLs and ignores anything else', () {
      final location = ProductsListLocation()
        ..remember('/products?sort=price_asc&page=3')
        ..remember('/products/$_creator')
        ..remember('/users?range=30d&page=1');

      expect(location.value, '/products?sort=price_asc&page=3');
    });
  });
}
