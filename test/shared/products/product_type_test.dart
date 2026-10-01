import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/shared/products/product_type.dart';

void main() {
  test('productTypeLabel humanizes the raw type', () {
    expect(productTypeLabel('OTHER_FRESH_PRODUCTS'), 'Other fresh products');
    expect(
      productTypeLabel('ICE_CREAM_AND_DESSERTS'),
      'Ice cream and desserts',
    );
    expect(productTypeLabel('DAIRY'), 'Dairy');
    expect(productTypeLabel('SOMETHING_NEW'), 'Something new');
  });

  test('kProductTypes matches the backend ProductType enum, in order', () {
    // modules/product/domain/model/ProductType.java
    expect(kProductTypes, [
      'FRUITS',
      'VEGETABLES',
      'OTHER_FRESH_PRODUCTS',
      'MEAT',
      'SEAFOOD',
      'DAIRY',
      'DELI',
      'BAKERY',
      'PANTRY',
      'SNACKS',
      'SWEETS',
      'FROZEN_FOODS',
      'ICE_CREAM_AND_DESSERTS',
      'BEVERAGES',
      'INTERNATIONAL',
      'SAUCES',
      'OTHER',
    ]);
  });
}
