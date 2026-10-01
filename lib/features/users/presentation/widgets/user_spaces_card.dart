import 'package:flutter/material.dart';

import '../../domain/entities/user_details.dart';

const kNoSpacesMessage = 'Not a member of any space';

class UserSpacesCard extends StatelessWidget {
  final List<UserSpace> spaces;

  const UserSpacesCard({super.key, required this.spaces});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spaces', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            if (spaces.isEmpty)
              Text(
                kNoSpacesMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final space in spaces)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.home_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(space.name)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
