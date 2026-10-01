import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/receipts/domain/entities/receipt_details.dart';
import 'package:fresh_keep_admin/features/receipts/domain/utils/receipt_totals.dart';
import 'package:fresh_keep_admin/shared/products/money.dart';

ReceiptProduct _product(
  num? amount, {
  String currency = 'USD',
  bool deleted = false,
}) => ReceiptProduct(
  id: 'p',
  name: 'Product',
  productType: 'DAIRY',
  expirationDate: null,
  price: amount == null ? null : Money(amount: amount, currency: currency),
  deleted: deleted,
);

void main() {
  test('sums one currency', () {
    expect(
      receiptTotals([_product(1.5), _product(2.25), _product(3)]),
      const ReceiptTotals(
        totals: [Money(amount: 6.75, currency: 'USD')],
        withoutPrice: 0,
      ),
    );
  });

  test('sums in cents: 0.1 + 0.2 is 0.30', () {
    final totals = receiptTotals([_product(0.1), _product(0.2)]);
    expect(totals.totals.single.amount, 0.3);
  });

  test('one total per currency, in first-seen order', () {
    expect(
      receiptTotals([
        _product(2, currency: 'EUR'),
        _product(1, currency: 'USD'),
        _product(3, currency: 'EUR'),
      ]).totals,
      const [
        Money(amount: 5, currency: 'EUR'),
        Money(amount: 1, currency: 'USD'),
      ],
    );
  });

  test('skips deleted products, priced or not', () {
    expect(
      receiptTotals([
        _product(1),
        _product(50, deleted: true),
        _product(null, deleted: true),
      ]),
      const ReceiptTotals(
        totals: [Money(amount: 1, currency: 'USD')],
        withoutPrice: 0,
      ),
    );
  });

  test('counts products without a price', () {
    expect(
      receiptTotals([_product(1), _product(null), _product(null)]),
      const ReceiptTotals(
        totals: [Money(amount: 1, currency: 'USD')],
        withoutPrice: 2,
      ),
    );
  });

  test('an empty receipt has no totals', () {
    expect(
      receiptTotals(const []),
      const ReceiptTotals(totals: [], withoutPrice: 0),
    );
  });
}
