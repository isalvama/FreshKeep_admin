import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_sort.dart';

void main() {
  test('maps every sort to the backend value and a lowercase URL value', () {
    expect(
      {for (final s in ProductSort.values) s: s.backendValue},
      {
        ProductSort.nameAsc: 'NAME_ASC',
        ProductSort.nameDesc: 'NAME_DESC',
        ProductSort.expirationAsc: 'EXPIRATION_DATE_ASC',
        ProductSort.expirationDesc: 'EXPIRATION_DATE_DESC',
        ProductSort.priceAsc: 'PRICE_ASC',
        ProductSort.priceDesc: 'PRICE_DESC',
      },
    );
    expect(ProductSort.expirationAsc.urlValue, 'expiration_date_asc');
  });

  test('fromUrlValue round-trips and rejects anything else', () {
    for (final sort in ProductSort.values) {
      expect(ProductSort.fromUrlValue(sort.urlValue), sort);
    }
    expect(ProductSort.fromUrlValue('NAME_ASC'), isNull);
    expect(ProductSort.fromUrlValue('name'), isNull);
    expect(ProductSort.fromUrlValue(null), isNull);
  });
}
