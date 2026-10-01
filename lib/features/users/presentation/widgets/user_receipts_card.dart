import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../domain/entities/user_details.dart';

const kNoReceiptsMessage = 'No receipts yet';

/// The receipts table scrolls inside the card past this height: the backend
/// returns all of a user's receipts at once.
const _maxTableHeight = 360.0;

/// The user's receipts, newest first; a row opens that receipt.
class UserReceiptsCard extends StatelessWidget {
  final List<UserReceipt> receipts;
  final ValueChanged<UserReceipt> onReceiptSelected;

  const UserReceiptsCard({
    super.key,
    required this.receipts,
    required this.onReceiptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final newestFirst = [...receipts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Receipts', style: textTheme.titleMedium),
            Text(
              'Includes unconfirmed receipts',
              style: textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            if (receipts.isEmpty)
              Text(kNoReceiptsMessage, style: TextStyle(color: muted))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _maxTableHeight),
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Store')),
                            DataColumn(label: Text('Purchase date')),
                            DataColumn(label: Text('Created')),
                          ],
                          rows: [
                            for (final receipt in newestFirst)
                              DataRow(
                                onSelectChanged: (_) =>
                                    onReceiptSelected(receipt),
                                cells: [
                                  DataCell(
                                    Text(receipt.storeName ?? kMissingValue),
                                  ),
                                  DataCell(
                                    Text(formatDate(receipt.purchaseDate)),
                                  ),
                                  DataCell(
                                    Text(formatDateTime(receipt.createdAt)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
