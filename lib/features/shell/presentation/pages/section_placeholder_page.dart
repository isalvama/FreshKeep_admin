import 'package:flutter/material.dart';

import '../shell_destination.dart';

/// Stands in for a section until the spec that builds it lands.
class SectionPlaceholderPage extends StatelessWidget {
  final ShellDestination destination;

  const SectionPlaceholderPage({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final spec = destination.comingInSpec.toString().padLeft(2, '0');
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(destination.icon, size: 48, color: colors.outline),
          const SizedBox(height: 16),
          Text(
            'Coming in SPEC $spec',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
