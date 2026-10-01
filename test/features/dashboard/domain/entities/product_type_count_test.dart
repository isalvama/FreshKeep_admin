import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/product_type_count.dart';

void main() {
  test('ProductTypeCount.label humanizes the raw type', () {
    String label(String type) =>
        ProductTypeCount(productType: type, count: 1).label;

    expect(label('OTHER_FRESH_PRODUCTS'), 'Other fresh products');
    expect(label('ICE_CREAM_AND_DESSERTS'), 'Ice cream and desserts');
    expect(label('DAIRY'), 'Dairy');
    expect(label('SOMETHING_NEW'), 'Something new');
  });
}
