import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../../../shared/products/format_money.dart';
import '../../../../shared/products/product_type.dart';
import '../../../../shared/products/widgets/expiration_cell.dart';
import '../../domain/entities/receipt_details.dart';
import '../../domain/utils/receipt_totals.dart';

const kNoProductsOnReceipt = 'No products on this receipt';
const kDeletedLabel = 'Deleted';

String withoutPriceNote(int count) => count == 1
    ? '1 product without a price'
    : '$count products without a price';

/// The receipt's products, oldest first. Deleted ones stay listed (they were
/// on the receipt) but are labelled, can't be opened, and don't count in the
/// total.
class ReceiptProductsCard extends StatelessWidget {
  final List<ReceiptProduct> products;
  final DateTime today;
  final ValueChanged<ReceiptProduct> onProductSelected;

  const ReceiptProductsCard({
    super.key,
    required this.products,
    required this.today,
    required this.onProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Products', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(kNoProductsOnReceipt, textAlign: TextAlign.center),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: _table(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Totals(totals: receiptTotals(products)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _table() {
    return DataTable(
      showCheckboxColumn: false,
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Expires')),
        DataColumn(label: Text('Price'), numeric: true),
      ],
      rows: [
        for (final product in products)
          DataRow(
            key: ValueKey('receipt-product-${product.id}'),
            // A deleted product has no page to open.
            onSelectChanged: product.deleted
                ? null
                : (_) => onProductSelected(product),
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(product.name),
                    if (product.deleted) ...[
                      const SizedBox(width: 8),
                      const _DeletedLabel(),
                    ],
                  ],
                ),
              ),
              DataCell(Text(productTypeLabel(product.productType))),
              DataCell(
                ExpirationCell(day: product.expirationDate, today: today),
              ),
              DataCell(
                Text(
                  product.price == null
                      ? kMissingValue
                      : formatMoney(product.price!),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DeletedLabel extends StatelessWidget {
  const _DeletedLabel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            kDeletedLabel,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final ReceiptTotals totals;

  const _Totals({required this.totals});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const Key('receipt-totals'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final total in totals.totals)
          Text('Total ${formatMoney(total)}', style: textTheme.titleSmall),
        if (totals.withoutPrice > 0)
          Text(
            withoutPriceNote(totals.withoutPrice),
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
