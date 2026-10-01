import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/product_type_count.dart';

void main() {
  test('ProductTypeCount.label uses the shared product type label', () {
    expect(
      const ProductTypeCount(
        productType: 'OTHER_FRESH_PRODUCTS',
        count: 1,
      ).label,
      'Other fresh products',
    );
  });
}
