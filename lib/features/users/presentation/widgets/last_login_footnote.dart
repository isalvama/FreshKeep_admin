import 'package:flutter/material.dart';

const kLastLoginFootnote =
    'For users who have never logged in, Last login shows their registration '
    'time.';

/// The backend defaults `last_log_in` to the registration time, so the UI
/// says so instead of guessing who has really logged in.
class LastLoginFootnote extends StatelessWidget {
  const LastLoginFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      kLastLoginFootnote,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
