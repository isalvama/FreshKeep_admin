import 'package:flutter/material.dart';

import '../../../../shared/metrics/presentation/format.dart';
import '../../domain/entities/registered_user.dart';

/// One row per user; tapping a row opens that user.
class UsersTable extends StatelessWidget {
  final List<RegisteredUser> users;
  final ValueChanged<RegisteredUser> onUserSelected;

  const UsersTable({
    super.key,
    required this.users,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Fills the card when the columns fit; scrolls sideways when they don't
    // (narrow windows, long emails) instead of squeezing columns.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: _table(),
        ),
      ),
    );
  }

  Widget _table() {
    return DataTable(
      showCheckboxColumn: false,
      columns: const [
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Username')),
        DataColumn(label: Text('Registered')),
        DataColumn(label: Text('Last login')),
      ],
      rows: [
        for (final user in users)
          DataRow(
            key: ValueKey('user-row-${user.id}'),
            onSelectChanged: (_) => onUserSelected(user),
            cells: [
              DataCell(Text(user.email)),
              DataCell(Text(user.username ?? kMissingValue)),
              DataCell(Text(formatDateTime(user.registeredAt))),
              DataCell(
                Text(
                  user.lastLoggedAt == null
                      ? kMissingValue
                      : formatDateTime(user.lastLoggedAt!),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
