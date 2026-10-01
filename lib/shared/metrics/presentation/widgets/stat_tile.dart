import 'package:flutter/material.dart';

import '../section_state.dart';
import '../format.dart';

/// A headline number: the total of one metric over the selected range.
/// Follows its metric's section state (spinner while loading, a dash on
/// failure; the chart card below explains the error).
class StatTile extends StatelessWidget {
  final String label;
  final SectionStatus status;
  final int? value;

  const StatTile({
    super.key,
    required this.label,
    required this.status,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: switch (status) {
                  SectionStatus.loading => const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SectionStatus.failure => Text(
                    '—',
                    semanticsLabel: 'Unavailable',
                    style: textTheme.headlineMedium,
                  ),
                  SectionStatus.loaded => Text(
                    formatCount(value ?? 0),
                    style: textTheme.headlineMedium,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
