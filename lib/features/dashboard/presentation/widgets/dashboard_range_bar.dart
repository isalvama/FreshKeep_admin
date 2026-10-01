import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_range.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/utils/calendar_day.dart';
import '../format/dashboard_format.dart';

const kRangeTooLongMessage =
    'Choose a range of at most $kMaxRangeLengthInDays days.';

/// Opens a date-range picker; returns null when dismissed.
typedef DateRangePicker =
    Future<DateTimeRange?> Function(
      BuildContext context, {
      required DateTimeRange initialRange,
      required DateTime firstDate,
      required DateTime lastDate,
    });

Future<DateTimeRange?> showMaterialDateRangePicker(
  BuildContext context, {
  required DateTimeRange initialRange,
  required DateTime firstDate,
  required DateTime lastDate,
}) => showDateRangePicker(
  context: context,
  initialDateRange: initialRange,
  firstDate: firstDate,
  lastDate: lastDate,
  helpText: 'Select a range of up to $kMaxRangeLengthInDays days',
);

/// The row above the dashboard: preset ranges, a custom range, the dates
/// being shown, and Refresh. It only reports choices; the page puts them in
/// the URL.
class DashboardRangeBar extends StatelessWidget {
  final DashboardRange range;
  final DateRange resolvedRange;
  final DateTime today;
  final ValueChanged<DashboardRange> onRangeChanged;
  final VoidCallback onRefresh;
  final DateRangePicker pickDateRange;

  const DashboardRangeBar({
    super.key,
    required this.range,
    required this.resolvedRange,
    required this.today,
    required this.onRangeChanged,
    required this.onRefresh,
    this.pickDateRange = showMaterialDateRangePicker,
  });

  Future<void> _pickCustom(BuildContext context) async {
    final lastDay = calendarDay(today);
    // The picker works in local dates; calendar days are UTC midnights.
    DateTime local(DateTime day) => DateTime(day.year, day.month, day.day);

    final picked = await pickDateRange(
      context,
      initialRange: DateTimeRange(
        start: local(resolvedRange.from),
        end: local(resolvedRange.to),
      ),
      firstDate: DateTime(lastDay.year - 5),
      lastDate: local(lastDay), // no future dates
    );
    if (picked == null || !context.mounted) return;

    final custom = DateRange(from: picked.start, to: picked.end);
    if (custom.lengthInDays > kMaxRangeLengthInDays) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(kRangeTooLongMessage)));
      return;
    }
    onRangeChanged(CustomRange(custom));
  }

  @override
  Widget build(BuildContext context) {
    final preset = switch (range) {
      PresetRange(:final preset) => preset,
      CustomRange() => null,
    };
    final shownDates =
        '${formatDate(resolvedRange.from)} – ${formatDate(resolvedRange.to)}';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<RangePreset>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            for (final p in RangePreset.values)
              ButtonSegment(value: p, label: Text(p.label)),
          ],
          selected: {?preset},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onRangeChanged(PresetRange(selection.single));
            }
          },
        ),
        OutlinedButton.icon(
          key: const Key('custom-range-button'),
          onPressed: () => _pickCustom(context),
          icon: const Icon(Icons.date_range),
          label: Text(preset == null ? shownDates : 'Custom…'),
          style: preset == null
              ? OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                )
              : null,
        ),
        if (preset != null)
          Text(
            shownDates,
            key: const Key('shown-dates'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}
