import 'package:flutter/material.dart';

import '../bloc/dashboard_bloc.dart';

/// Height of a card's chart or table area, so toggling doesn't move the page.
const kChartCardBodyHeight = 260.0;

enum ChartView { chart, table }

/// A titled card around one chart, owning its section's states: loading,
/// error with Retry, empty, and — once loaded — a Chart | Table toggle.
///
/// The toggle is local widget state: pure presentation, no logic or events
/// (a deliberate exception to "toggles use a Cubit", see SPEC 02 Decisions).
class ChartCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final SectionStatus status;
  final String? errorMessage;
  final VoidCallback onRetry;

  /// Whether the loaded data has nothing to show (e.g. all-zero days).
  final bool isEmpty;
  final String emptyMessage;
  final WidgetBuilder chartBuilder;
  final WidgetBuilder tableBuilder;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.status,
    this.errorMessage,
    required this.onRetry,
    required this.isEmpty,
    required this.emptyMessage,
    required this.chartBuilder,
    required this.tableBuilder,
  });

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  var _view = ChartView.chart;

  bool get _hasData => widget.status == SectionStatus.loaded && !widget.isEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: textTheme.titleMedium),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_hasData)
                  SegmentedButton<ChartView>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: ChartView.chart,
                        label: Text('Chart'),
                        icon: Icon(Icons.bar_chart),
                      ),
                      ButtonSegment(
                        value: ChartView.table,
                        label: Text('Table'),
                        icon: Icon(Icons.table_rows_outlined),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (selection) =>
                        setState(() => _view = selection.single),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: kChartCardBodyHeight, child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (widget.status) {
      case SectionStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SectionStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colors.error),
              const SizedBox(height: 8),
              Text(
                widget.errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      case SectionStatus.loaded:
        if (widget.isEmpty) {
          return Center(
            child: Text(
              widget.emptyMessage,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          );
        }
        return _view == ChartView.chart
            ? widget.chartBuilder(context)
            : widget.tableBuilder(context);
    }
  }
}
