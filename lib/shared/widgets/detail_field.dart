import 'package:flutter/material.dart';

/// A "Label   value" row in a detail card.
class DetailField extends StatelessWidget {
  final String label;
  final Widget value;

  const DetailField({super.key, required this.label, required this.value});

  DetailField.text({super.key, required this.label, required String text})
    : value = Text(text);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: DefaultTextStyle.merge(
              style: textTheme.bodyMedium,
              child: Align(alignment: Alignment.centerLeft, child: value),
            ),
          ),
        ],
      ),
    );
  }
}
