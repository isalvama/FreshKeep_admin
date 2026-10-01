import 'package:flutter/material.dart';

import '../../metrics/presentation/format.dart';
import '../expiration_status.dart';

const kExpiredLabel = 'Expired';
const kExpiresSoonLabel = 'Expires soon';

/// An expiration date with a status badge ("Expired", "Expires soon"). The
/// badge always pairs its color with an icon and a label.
class ExpirationCell extends StatelessWidget {
  /// A calendar day (UTC midnight); null shows "—".
  final DateTime? day;
  final DateTime today;

  const ExpirationCell({super.key, required this.day, required this.today});

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    if (day == null) return const Text(kMissingValue);
    final badge = switch (expirationStatus(day, today)) {
      ExpirationStatus.expired => const ExpirationBadge.expired(),
      ExpirationStatus.soon => const ExpirationBadge.soon(),
      ExpirationStatus.ok => null,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatDate(day)),
        if (badge != null) ...[const SizedBox(width: 8), badge],
      ],
    );
  }
}

class ExpirationBadge extends StatelessWidget {
  final bool expired;

  const ExpirationBadge.expired({super.key}) : expired = true;
  const ExpirationBadge.soon({super.key}) : expired = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = expired
        ? colors.errorContainer
        : colors.tertiaryContainer;
    final foreground = expired
        ? colors.onErrorContainer
        : colors.onTertiaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expired ? Icons.warning_amber_rounded : Icons.schedule,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            expired ? kExpiredLabel : kExpiresSoonLabel,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
