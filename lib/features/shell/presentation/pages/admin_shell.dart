import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../shell_destination.dart';
import '../widgets/narrow_screen_notice.dart';

/// Below this width only [NarrowScreenNotice] is shown.
const kMinShellWidth = 600.0;

/// From this width the rail shows labels next to its icons.
const kLabelledRailWidth = 1000.0;

/// Frame around every authenticated section: navigation rail, top bar with
/// the admin's email and Logout, and the section page as [child].
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = shellDestinations.indexWhere((d) => d.matches(path));
    final selected = selectedIndex == -1
        ? null
        : shellDestinations[selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kMinShellWidth) {
          return const NarrowScreenNotice();
        }
        final labelled = constraints.maxWidth >= kLabelledRailWidth;

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: labelled,
                selectedIndex: selectedIndex == -1 ? null : selectedIndex,
                onDestinationSelected: (index) =>
                    context.go(shellDestinations[index].path),
                leading: _RailHeader(labelled: labelled),
                destinations: [
                  for (final destination in shellDestinations)
                    NavigationRailDestination(
                      // Collapsed, the icon is all there is: the tooltip names it.
                      icon: labelled
                          ? Icon(destination.icon)
                          : Tooltip(
                              message: destination.label,
                              child: Icon(destination.icon),
                            ),
                      selectedIcon: labelled
                          ? Icon(destination.selectedIcon)
                          : Tooltip(
                              message: destination.label,
                              child: Icon(destination.selectedIcon),
                            ),
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(title: selected?.label ?? ''),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RailHeader extends StatelessWidget {
  final bool labelled;

  const _RailHeader({required this.labelled});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = Icon(Icons.eco, color: colors.primary, size: 32);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: labelled
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  'Fresh Keep Admin',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            )
          : icon,
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthBloc, String>(
      (bloc) => switch (bloc.state) {
        Authenticated(:final admin) => admin.email,
        _ => '',
      },
    );

    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(title),
      actions: [
        Text(email, key: const Key('shell-admin-email')),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => context.read<AuthBloc>().add(const LoggedOut()),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
