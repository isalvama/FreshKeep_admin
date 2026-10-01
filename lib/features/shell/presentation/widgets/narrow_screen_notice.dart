import 'package:flutter/material.dart';

/// Replaces the whole shell on windows narrower than 600px: the admin app is
/// desktop-first and has no phone layout.
class NarrowScreenNotice extends StatelessWidget {
  const NarrowScreenNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.desktop_windows_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Please use a larger screen',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Fresh Keep Admin needs a window at least 600 pixels wide.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
