import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/chart_colors.dart';
import '../../../../shared/metrics/presentation/format.dart';
import '../../../../shared/widgets/text_link.dart';
import '../../domain/entities/product_type_count.dart';

const _labelWidth = 168.0;
const _valueWidth = 56.0;
const _barHeight = 14.0;

/// Horizontal bars, one row per type (expects [counts] already sorted),
/// each scaled to the largest count, with the count at the bar's end.
///
/// Plain widgets rather than fl_chart: fl_chart has no native horizontal
/// bars (see SPEC 02 Decisions).
class ProductTypeBarChart extends StatelessWidget {
  final List<ProductTypeCount> counts;

  /// When set, each type's label is a link that receives the raw type.
  final ValueChanged<String>? onTypeSelected;

  const ProductTypeBarChart({
    super.key,
    required this.counts,
    this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final largest = counts.fold<int>(0, (m, c) => max(m, c.count));
    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
      itemCount: counts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final count = counts[index];
        final fraction = largest == 0 ? 0.0 : count.count / largest;
        return MergeSemantics(
          child: Row(
            children: [
              SizedBox(
                width: _labelWidth,
                child: onTypeSelected == null
                    ? Text(
                        count.label,
                        style: textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: TextLink(
                          key: ValueKey('type-link-${count.productType}'),
                          text: count.label,
                          style: textTheme.bodySmall,
                          onPressed: () => onTypeSelected!(count.productType),
                        ),
                      ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barMax = max(0.0, constraints.maxWidth - _valueWidth);
                    return Row(
                      children: [
                        Container(
                          key: ValueKey('type-bar-${count.productType}'),
                          width: barMax * fraction,
                          height: _barHeight,
                          decoration: const BoxDecoration(
                            color: kChartSeriesColor,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatCount(count.count),
                          style: textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
