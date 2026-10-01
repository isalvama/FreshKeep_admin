import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_summary.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/products_page.dart';

void main() {
  List<ProductSummary> rows(int count) => [
    for (var i = 0; i < count; i++)
      ProductSummary(
        id: 'p$i',
        name: 'Product $i',
        productType: 'DAIRY',
        expirationDate: null,
        price: null,
      ),
  ];

  test('a full page may have a next one', () {
    final page = ProductsPage(products: rows(30), page: 2, size: 30);
    expect(page.hasNext, isTrue);
    expect(page.hasPrevious, isTrue);
    expect((page.firstIndex, page.lastIndex), (31, 60));
  });

  test('a short page is the last one', () {
    final page = ProductsPage(products: rows(7), page: 3, size: 30);
    expect(page.hasNext, isFalse);
    expect((page.firstIndex, page.lastIndex), (61, 67));
  });

  test('the first page has no previous one', () {
    final page = ProductsPage(products: rows(30), page: 1, size: 30);
    expect(page.hasPrevious, isFalse);
    expect((page.firstIndex, page.lastIndex), (1, 30));
  });

  test('an empty page has no rows and no next page', () {
    final page = ProductsPage(products: const [], page: 4, size: 30);
    expect(page.hasNext, isFalse);
    expect(page.hasPrevious, isTrue);
    expect((page.firstIndex, page.lastIndex), (0, 0));
  });
}
