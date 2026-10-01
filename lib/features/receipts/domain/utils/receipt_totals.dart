import 'package:equatable/equatable.dart';

import '../../../../shared/products/money.dart';
import '../entities/receipt_details.dart';

/// What a receipt's products add up to: one total per currency, plus how many
/// products had no price.
class ReceiptTotals extends Equatable {
  /// In the order each currency first appears.
  final List<Money> totals;
  final int withoutPrice;

  const ReceiptTotals({required this.totals, required this.withoutPrice});

  @override
  List<Object?> get props => [totals, withoutPrice];
}

/// Totals of the products still in their space (deleted ones are skipped).
/// Amounts are summed in whole cents, so `0.1 + 0.2` is `0.30`, not
/// `0.30000000000000004`.
ReceiptTotals receiptTotals(List<ReceiptProduct> products) {
  final cents = <String, int>{};
  var withoutPrice = 0;
  for (final product in products) {
    if (product.deleted) continue;
    final price = product.price;
    if (price == null) {
      withoutPrice++;
      continue;
    }
    cents.update(
      price.currency,
      (sum) => sum + (price.amount * 100).round(),
      ifAbsent: () => (price.amount * 100).round(),
    );
  }
  return ReceiptTotals(
    totals: [
      for (final MapEntry(key: currency, value: sum) in cents.entries)
        Money(amount: sum / 100, currency: currency),
    ],
    withoutPrice: withoutPrice,
  );
}
