import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../domain/entities/receipt_summary.dart';

/// One row per receipt; tapping a row opens that receipt.
class ReceiptsTable extends StatelessWidget {
  final List<ReceiptSummary> receipts;
  final ValueChanged<ReceiptSummary> onReceiptSelected;

  const ReceiptsTable({
    super.key,
    required this.receipts,
    required this.onReceiptSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Fills the card when the columns fit; scrolls sideways when they don't.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: _table(),
        ),
      ),
    );
  }

  Widget _table() {
    return DataTable(
      showCheckboxColumn: false,
      columns: const [
        DataColumn(label: Text('Purchased')),
        DataColumn(label: Text('Store')),
        DataColumn(label: Text('Added by')),
        DataColumn(label: Text('Space')),
        DataColumn(label: Text('Products'), numeric: true),
      ],
      rows: [
        for (final receipt in receipts)
          DataRow(
            onSelectChanged: (_) => onReceiptSelected(receipt),
            cells: [
              DataCell(Text(formatDate(receipt.purchaseDate))),
              DataCell(Text(receipt.storeName ?? kMissingValue)),
              DataCell(Text(receipt.creatorEmail ?? kMissingValue)),
              DataCell(Text(receipt.spaceName ?? kMissingValue)),
              DataCell(Text(formatCount(receipt.productCount))),
            ],
          ),
      ],
    );
  }
}
