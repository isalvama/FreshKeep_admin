import 'package:flutter/material.dart';

/// A section of the admin shell. Later specs fill a destination's page;
/// they never add navigation outside this list.
class ShellDestination {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// The spec that builds this section, shown on its placeholder until then.
  final int comingInSpec;

  const ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.comingInSpec,
  });

  /// Whether [location] (a URL path) belongs to this section: the section
  /// itself or a page under it (`/users/<id>`). Look-alikes such as
  /// `/userszzz`, and a bare trailing slash, don't match.
  bool matches(String location) =>
      location == path ||
      (location.startsWith('$path/') && location.length > path.length + 1);
}

const shellDestinations = [
  ShellDestination(
    path: '/dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    comingInSpec: 2,
  ),
  ShellDestination(
    path: '/users',
    label: 'Users',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    comingInSpec: 3,
  ),
  ShellDestination(
    path: '/products',
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    comingInSpec: 4,
  ),
  ShellDestination(
    path: '/receipts',
    label: 'Receipts',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    comingInSpec: 5,
  ),
  ShellDestination(
    path: '/admins',
    label: 'Admins',
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings,
    comingInSpec: 6,
  ),
];
