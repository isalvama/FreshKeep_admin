import 'package:flutter/material.dart';

import '../../../../shared/creators/creator_filter_chip.dart';
import '../../../../shared/metrics/presentation/format.dart';
import '../../../../shared/metrics/presentation/section_state.dart';
import '../../../../shared/products/product_type.dart';
import '../../domain/entities/product_filters.dart';
import '../../domain/entities/product_sort.dart';
import '../../domain/entities/receipt_label.dart';

const kAllTypesLabel = 'All types';

String productSortLabel(ProductSort sort) => switch (sort) {
  ProductSort.nameAsc => 'Name A–Z',
  ProductSort.nameDesc => 'Name Z–A',
  ProductSort.expirationAsc => 'Expires soonest',
  ProductSort.expirationDesc => 'Expires latest',
  ProductSort.priceAsc => 'Price low–high',
  ProductSort.priceDesc => 'Price high–low',
};

String receiptChipLabel(String receiptId, SectionState<ReceiptLabel>? label) {
  switch (label?.status) {
    case SectionStatus.loaded:
      final receipt = label!.data!;
      final date = formatDate(receipt.purchaseDate);
      return receipt.storeName == null
          ? 'Receipt: $date'
          : 'Receipt: ${receipt.storeName} · $date';
    case SectionStatus.failure:
      return 'Receipt ${shortId(receiptId)}';
    case SectionStatus.loading || null:
      return 'Receipt …';
  }
}

/// Sort and type dropdowns, plus a removable chip per creator or receipt
/// filter. Every change goes through [onFiltersChanged]; the page turns it
/// into a URL.
class ProductsControls extends StatelessWidget {
  final ProductFilters filters;
  final SectionState<String>? creatorLabel;
  final SectionState<ReceiptLabel>? receiptLabel;
  final ValueChanged<ProductFilters> onFiltersChanged;

  const ProductsControls({
    super.key,
    required this.filters,
    required this.creatorLabel,
    required this.receiptLabel,
    required this.onFiltersChanged,
  });

  ProductFilters _with({
    ProductSort? sort,
    String? Function()? productType,
    String? Function()? creatorId,
    String? Function()? receiptId,
  }) => ProductFilters(
    sort: sort ?? filters.sort,
    productType: productType == null ? filters.productType : productType(),
    creatorId: creatorId == null ? filters.creatorId : creatorId(),
    receiptId: receiptId == null ? filters.receiptId : receiptId(),
  );

  @override
  Widget build(BuildContext context) {
    final creatorId = filters.creatorId;
    final receiptId = filters.receiptId;
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Keyed by value: a form field reads initialValue once, and the
        // filters can also change from the URL (e.g. browser Back).
        SizedBox(
          key: const Key('products-sort'),
          width: 200,
          child: DropdownButtonFormField<ProductSort>(
            key: ValueKey(filters.sort),
            // Long labels ellipsize instead of overflowing the field.
            isExpanded: true,
            initialValue: filters.sort,
            decoration: const InputDecoration(
              labelText: 'Sort by',
              isDense: true,
            ),
            items: [
              for (final sort in ProductSort.values)
                DropdownMenuItem(
                  value: sort,
                  child: Text(productSortLabel(sort)),
                ),
            ],
            onChanged: (sort) {
              if (sort != null && sort != filters.sort) {
                onFiltersChanged(_with(sort: sort));
              }
            },
          ),
        ),
        SizedBox(
          key: const Key('products-type'),
          width: 240,
          child: DropdownButtonFormField<String?>(
            key: ValueKey(filters.productType),
            // Long labels ellipsize instead of overflowing the field.
            isExpanded: true,
            initialValue: filters.productType,
            decoration: const InputDecoration(labelText: 'Type', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text(kAllTypesLabel)),
              for (final type in kProductTypes)
                DropdownMenuItem(
                  value: type,
                  child: Text(productTypeLabel(type)),
                ),
            ],
            onChanged: (type) {
              if (type != filters.productType) {
                onFiltersChanged(_with(productType: () => type));
              }
            },
          ),
        ),
        if (creatorId != null)
          CreatorFilterChip(
            creatorId: creatorId,
            label: creatorLabel,
            onDeleted: () => onFiltersChanged(_with(creatorId: () => null)),
          ),
        if (receiptId != null)
          InputChip(
            key: const Key('receipt-chip'),
            avatar: const Icon(Icons.receipt_long_outlined, size: 18),
            label: Text(receiptChipLabel(receiptId, receiptLabel)),
            deleteButtonTooltipMessage: 'Remove receipt filter',
            onDeleted: () => onFiltersChanged(_with(receiptId: () => null)),
          ),
      ],
    );
  }
}
