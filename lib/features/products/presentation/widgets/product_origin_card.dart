import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../domain/entities/product_details.dart';
import '../../../../shared/widgets/text_link.dart';
import 'detail_field.dart';

const kNoReceiptMessage = 'Not added from a shopping receipt.';
const kOtherProductsOnReceipt = 'Other products on this receipt';

/// Where a product came from: who added it, in which space, from which
/// store's receipt.
class ProductOriginCard extends StatelessWidget {
  /// Null when the product isn't on a receipt.
  final ProductOrigin? origin;
  final ValueChanged<String> onCreatorSelected;
  final ValueChanged<String> onReceiptSelected;

  const ProductOriginCard({
    super.key,
    required this.origin,
    required this.onCreatorSelected,
    required this.onReceiptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final origin = this.origin;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Origin', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (origin == null)
              const Text(kNoReceiptMessage)
            else ...[
              DetailField(label: 'Added by', value: _creator(origin)),
              DetailField.text(
                label: 'Space',
                text: origin.spaceName ?? kMissingValue,
              ),
              DetailField.text(
                label: 'Store',
                text: origin.storeName ?? kMissingValue,
              ),
              DetailField.text(
                label: 'Purchased',
                text: origin.purchaseDate == null
                    ? kMissingValue
                    : formatDate(origin.purchaseDate!),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('receipt-products-link'),
                onPressed: () => onReceiptSelected(origin.receiptId),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text(kOtherProductsOnReceipt),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _creator(ProductOrigin origin) {
    final creatorId = origin.creatorId;
    final name = [
      ?origin.creatorEmail,
      if (origin.creatorUsername != null) '(${origin.creatorUsername})',
    ].join(' ');
    // The creator can be gone (the receipt keeps a null creator).
    if (creatorId == null) return const Text(kMissingValue);
    return TextLink(
      key: const Key('creator-link'),
      text: name.isEmpty ? creatorId : name,
      onPressed: () => onCreatorSelected(creatorId),
    );
  }
}
