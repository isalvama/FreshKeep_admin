import 'package:flutter/material.dart';

import '../metrics/presentation/section_state.dart';

/// `3f2a9c1e…`: what a chip shows when its label couldn't be looked up.
String shortId(String id) => id.length <= 8 ? id : '${id.substring(0, 8)}…';

String creatorChipLabel(String creatorId, SectionState<String>? label) =>
    switch (label?.status) {
      SectionStatus.loaded => 'Added by ${label!.data}',
      SectionStatus.failure => 'Added by ${shortId(creatorId)}',
      _ => 'Added by …',
    };

/// "Added by alice@example.com ✕": a list's creator filter, removable.
class CreatorFilterChip extends StatelessWidget {
  final String creatorId;

  /// The creator's email, as it loads.
  final SectionState<String>? label;
  final VoidCallback onDeleted;

  const CreatorFilterChip({
    super.key = const Key('creator-chip'),
    required this.creatorId,
    required this.label,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: const Icon(Icons.person_outline, size: 18),
      label: Text(creatorChipLabel(creatorId, label)),
      deleteButtonTooltipMessage: 'Remove creator filter',
      onDeleted: onDeleted,
    );
  }
}
