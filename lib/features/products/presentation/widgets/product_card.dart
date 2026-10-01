import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../../../shared/products/product_type.dart';
import '../../domain/entities/product_details.dart';
import '../format_money.dart';
import 'detail_field.dart';
import 'expiration_cell.dart';

class ProductCard extends StatelessWidget {
  final ProductDetails product;
  final DateTime today;

  const ProductCard({super.key, required this.product, required this.today});

  @override
  Widget build(BuildContext context) {
    final price = product.price;
    final spot = product.storageSpotType;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DetailField.text(
              label: 'Type',
              text: productTypeLabel(product.productType),
            ),
            DetailField(
              label: 'Expires',
              value: ExpirationCell(day: product.expirationDate, today: today),
            ),
            DetailField.text(
              label: 'Price',
              text: price == null ? kMissingValue : formatMoney(price),
            ),
            DetailField.text(
              label: 'Stored in',
              text: spot == null ? kMissingValue : humanizeConstant(spot),
            ),
            DetailField.text(
              label: 'Added',
              text: formatDateTime(product.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}
