import 'package:flutter/material.dart';

import '../format/dashboard_format.dart';

/// The table view of a chart: one row per bar, with the same values. Gives
/// keyboard and screen-reader users every value without hovering.
class CountsTable extends StatelessWidget {
  final String labelHeader;
  final String countHeader;
  final List<(String, int)> rows;

  const CountsTable({
    super.key,
    required this.labelHeader,
    this.countHeader = 'Count',
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 32,
          columns: [
            DataColumn(label: Text(labelHeader)),
            DataColumn(label: Text(countHeader), numeric: true),
          ],
          rows: [
            for (final (label, count) in rows)
              DataRow(
                cells: [
                  DataCell(Text(label)),
                  DataCell(Text(formatCount(count))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
