import 'package:flutter/material.dart';

import '../../domain/entities/date_range.dart';
import '../../domain/entities/selected_range.dart';
import '../../domain/utils/calendar_day.dart';
import '../format.dart';

String rangeTooLongMessage(int maxLengthInDays) =>
    'Choose a range of at most $maxLengthInDays days.';

/// Opens a date-range picker; returns null when dismissed.
typedef DateRangePicker =
    Future<DateTimeRange?> Function(
      BuildContext context, {
      required DateTimeRange initialRange,
      required DateTime firstDate,
      required DateTime lastDate,
      required String helpText,
    });

Future<DateTimeRange?> showMaterialDateRangePicker(
  BuildContext context, {
  required DateTimeRange initialRange,
  required DateTime firstDate,
  required DateTime lastDate,
  required String helpText,
}) => showDateRangePicker(
  context: context,
  initialDateRange: initialRange,
  firstDate: firstDate,
  lastDate: lastDate,
  helpText: helpText,
);

/// A row of range controls: preset ranges, a custom range, the dates being
/// shown, and Refresh. It only reports choices; the page puts them in the
/// URL.
class RangeBar extends StatelessWidget {
  final SelectedRange range;
  final DateRange resolvedRange;
  final DateTime today;
  final ValueChanged<SelectedRange> onRangeChanged;
  final VoidCallback onRefresh;
  final DateRangePicker pickDateRange;

  /// Longest custom range accepted (`to − from`); the endpoint's limit.
  final int maxLengthInDays;

  /// Optional text before the controls, e.g. "Registered between".
  final String? label;

  const RangeBar({
    super.key,
    required this.maxLengthInDays,
    this.label,
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
      helpText: 'Select a range of up to $maxLengthInDays days',
    );
    if (picked == null || !context.mounted) return;

    final custom = DateRange(from: picked.start, to: picked.end);
    if (custom.lengthInDays > maxLengthInDays) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(rangeTooLongMessage(maxLengthInDays))),
        );
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
        if (label != null)
          Text(label!, style: Theme.of(context).textTheme.titleSmall),
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
