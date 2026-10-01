import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../../../shared/widgets/detail_field.dart';
import '../../../../shared/widgets/text_link.dart';
import '../../domain/entities/receipt_details.dart';
import '../format_image_type.dart';

const kNoImage = 'No image';

/// Where and when a receipt was bought, and who uploaded it.
class ReceiptCard extends StatelessWidget {
  final ReceiptDetails receipt;
  final ValueChanged<String> onCreatorSelected;

  const ReceiptCard({
    super.key,
    required this.receipt,
    required this.onCreatorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final imageType = receipt.imageMimeType;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              receipt.storeName ?? 'Receipt',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DetailField.text(
              label: 'Store',
              text: receipt.storeName ?? kMissingValue,
            ),
            DetailField.text(
              label: 'Purchased',
              text: formatDate(receipt.purchaseDate),
            ),
            DetailField.text(
              label: 'Uploaded',
              text: formatDateTime(receipt.createdAt),
            ),
            DetailField(label: 'Added by', value: _creator()),
            DetailField.text(
              label: 'Space',
              text: receipt.spaceName ?? kMissingValue,
            ),
            DetailField.text(
              label: 'Image',
              text: imageType == null
                  ? kNoImage
                  : 'Image attached (${formatImageType(imageType)})',
            ),
          ],
        ),
      ),
    );
  }

  Widget _creator() {
    final creatorId = receipt.creatorId;
    // The creator can be gone (the receipt keeps a null creator).
    if (creatorId == null) return const Text(kMissingValue);
    final name = [
      ?receipt.creatorEmail,
      if (receipt.creatorUsername != null) '(${receipt.creatorUsername})',
    ].join(' ');
    return TextLink(
      key: const Key('creator-link'),
      text: name.isEmpty ? creatorId : name,
      onPressed: () => onCreatorSelected(creatorId),
    );
  }
}
