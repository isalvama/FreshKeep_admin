import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../domain/entities/users_page.dart';

/// "31–60 of 214" with Previous / Next.
class PaginationBar extends StatelessWidget {
  final UsersPage page;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final position =
        '${formatCount(page.firstIndex)}–${formatCount(page.lastIndex)} '
        'of ${formatCount(page.totalElements)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(position, key: const Key('pagination-position')),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Previous page',
          icon: const Icon(Icons.chevron_left),
          onPressed: page.hasPrevious
              ? () => onPageChanged(page.page - 1)
              : null,
        ),
        IconButton(
          tooltip: 'Next page',
          icon: const Icon(Icons.chevron_right),
          onPressed: page.hasNext ? () => onPageChanged(page.page + 1) : null,
        ),
      ],
    );
  }
}
