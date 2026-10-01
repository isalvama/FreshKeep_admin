import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../../../shared/products/product_type.dart';
import '../../domain/entities/product_summary.dart';
import '../../../../shared/products/format_money.dart';
import '../../../../shared/products/widgets/expiration_cell.dart';

/// One row per product; tapping a row opens that product.
class ProductsTable extends StatelessWidget {
  final List<ProductSummary> products;
  final DateTime today;
  final ValueChanged<ProductSummary> onProductSelected;

  const ProductsTable({
    super.key,
    required this.products,
    required this.today,
    required this.onProductSelected,
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
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Expires')),
        DataColumn(label: Text('Price'), numeric: true),
      ],
      rows: [
        for (final product in products)
          DataRow(
            onSelectChanged: (_) => onProductSelected(product),
            cells: [
              DataCell(Text(product.name)),
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
