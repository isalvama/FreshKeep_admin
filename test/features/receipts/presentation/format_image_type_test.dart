import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/format_image_type.dart';

void main() {
  test('shows the MIME subtype in capitals', () {
    expect(formatImageType('image/jpeg'), 'JPEG');
    expect(formatImageType('image/png'), 'PNG');
    expect(formatImageType('image/svg+xml'), 'SVG');
    expect(formatImageType('application/pdf'), 'PDF');
  });

  test('keeps an odd value as it is', () {
    expect(formatImageType('image/'), 'image/');
  });
}
