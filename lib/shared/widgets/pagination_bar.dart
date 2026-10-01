import 'package:flutter/material.dart';

import '../metrics/presentation/format.dart';

/// "31–60 of 214" (or "Products 31–60" when there is no total) with
/// Previous / Next.
class PaginationBar extends StatelessWidget {
  /// 1-based.
  final int page;
  final int firstIndex;
  final int lastIndex;

  /// Shown as "of N" when known.
  final int? total;

  /// Shown before the range, e.g. "Products".
  final String? label;
  final bool hasPrevious;
  final bool hasNext;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.firstIndex,
    required this.lastIndex,
    this.total,
    this.label,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final position = [
      ?label,
      '${formatCount(firstIndex)}–${formatCount(lastIndex)}',
      if (total != null) 'of ${formatCount(total!)}',
    ].join(' ');
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(position, key: const Key('pagination-position')),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Previous page',
          icon: const Icon(Icons.chevron_left),
          onPressed: hasPrevious ? () => onPageChanged(page - 1) : null,
        ),
        IconButton(
          tooltip: 'Next page',
          icon: const Icon(Icons.chevron_right),
          onPressed: hasNext ? () => onPageChanged(page + 1) : null,
        ),
      ],
    );
  }
}
