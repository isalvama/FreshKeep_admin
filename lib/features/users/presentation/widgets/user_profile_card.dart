import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../domain/entities/user_details.dart';
import 'last_login_footnote.dart';

/// `USER` → "User", `ADMIN` → "Admin"; unknown roles are humanized alike.
String roleLabel(String role) {
  final words = role.toLowerCase().replaceAll('_', ' ').trim();
  return words.isEmpty ? role : words[0].toUpperCase() + words.substring(1);
}

class UserProfileCard extends StatelessWidget {
  final UserDetails user;

  const UserProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget field(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in user.roles)
                  Chip(
                    label: Text(roleLabel(role)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            field('Username', user.username ?? kMissingValue),
            field('Registered', formatDateTime(user.registeredAt)),
            field(
              'Last login',
              user.lastLoggedAt == null
                  ? kMissingValue
                  : formatDateTime(user.lastLoggedAt!),
            ),
            const SizedBox(height: 4),
            const LastLoginFootnote(),
          ],
        ),
      ),
    );
  }
}
