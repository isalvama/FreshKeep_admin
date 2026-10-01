import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/chart_colors.dart';
import '../../domain/entities/daily_count.dart';
import '../format/dashboard_format.dart';

/// At most this many date labels along the bottom axis; the rest of the days
/// are reachable through the tooltip and the table view.
const _maxDateLabels = 8;

/// One column per day (expects zero-filled [days]), single series, hover
/// tooltip "Sep 14 · 3". No legend: the card title names the series.
class DailyColumnChart extends StatelessWidget {
  final List<DailyCount> days;

  const DailyColumnChart({super.key, required this.days});

  /// A round axis top above the largest count, with integer gridlines.
  static ({double maxY, double interval}) axisFor(List<DailyCount> days) {
    final largest = days.fold<int>(0, (m, d) => max(m, d.count));
    if (largest <= 4) return (maxY: max(largest, 1).toDouble(), interval: 1);
    final rawStep = largest / 4;
    final magnitude = pow(10, (log(rawStep) / ln10).floor()).toDouble();
    final step = [
      1,
      2,
      5,
      10,
    ].map((m) => m * magnitude).firstWhere((s) => s >= rawStep);
    return (maxY: (largest / step).ceil() * step, interval: step);
  }

  /// Show every [labelStep]-th day's date, so at most [_maxDateLabels] fit.
  static int labelStepFor(int dayCount) =>
      max(1, (dayCount / _maxDateLabels).ceil());

  /// "Sep 14 · 3", the tooltip text for one column.
  static String tooltipText(DailyCount day) =>
      '${formatShortDate(day.date)} · ${formatCount(day.count)}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final axisStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant);
    final axis = axisFor(days);
    final labelStep = labelStepFor(days.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Thin columns with a visible gap, whatever the range length.
        final slot = constraints.maxWidth / max(days.length, 1);
        final barWidth = (slot * 0.6).clamp(2.0, 24.0);

        return BarChart(
          BarChartData(
            maxY: axis.maxY,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            barGroups: [
              for (var i = 0; i < days.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: days[i].count.toDouble(),
                      color: kChartSeriesColor,
                      width: barWidth,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(min(4, barWidth / 2)),
                      ),
                    ),
                  ],
                ),
            ],
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: axis.interval,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: colors.outlineVariant, strokeWidth: 1),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(bottom: BorderSide(color: colors.outline)),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: axis.interval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(formatCount(value.round()), style: axisStyle),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index % labelStep != 0 || index >= days.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        formatShortDate(days[index].date),
                        style: axisStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              // The hit area is wider than a thin column.
              touchExtraThreshold: const EdgeInsets.symmetric(horizontal: 6),
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => colors.inverseSurface,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                      tooltipText(days[group.x]),
                      TextStyle(
                        color: colors.onInverseSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}
