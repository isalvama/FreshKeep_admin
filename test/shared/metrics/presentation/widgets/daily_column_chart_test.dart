import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/theme/chart_colors.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/daily_count.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/widgets/daily_column_chart.dart';

Future<void> _pump(WidgetTester tester, Widget chart) async {
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 800, height: 260, child: chart)),
    ),
  );
  await tester.pumpAndSettle();
}

List<DailyCount> _days(List<int> counts) => [
  for (var i = 0; i < counts.length; i++)
    DailyCount(date: DateTime.utc(2026, 9, 1 + i), count: counts[i]),
];

void main() {
  group('DailyColumnChart', () {
    BarChartData data(WidgetTester tester) =>
        tester.widget<BarChart>(find.byType(BarChart)).data;

    testWidgets('draws one column per day, in order, with its count', (
      tester,
    ) async {
      await _pump(tester, DailyColumnChart(days: _days([0, 3, 0, 5, 1])));

      final groups = data(tester).barGroups;
      expect(groups, hasLength(5));
      expect(groups.map((g) => g.x), [0, 1, 2, 3, 4]);
      expect(groups.map((g) => g.barRods.single.toY), [0, 3, 0, 5, 1]);
    });

    testWidgets('zero days are present as zero-height columns', (tester) async {
      await _pump(tester, DailyColumnChart(days: _days([0, 0, 2])));

      expect(data(tester).barGroups[0].barRods.single.toY, 0);
      expect(data(tester).barGroups[1].barRods.single.toY, 0);
    });

    testWidgets('a 90-day range draws 90 columns', (tester) async {
      await _pump(tester, DailyColumnChart(days: _days(List.filled(90, 1))));

      expect(data(tester).barGroups, hasLength(90));
    });

    testWidgets('every column uses the validated series color', (tester) async {
      await _pump(tester, DailyColumnChart(days: _days([1, 2, 3])));

      for (final group in data(tester).barGroups) {
        expect(group.barRods.single.color, kChartSeriesColor);
      }
    });

    testWidgets('the tooltip shows the date and count', (tester) async {
      await _pump(tester, DailyColumnChart(days: _days([0, 1234])));

      final chart = data(tester);
      final group = chart.barGroups[1];
      final item = chart.barTouchData.touchTooltipData.getTooltipItem(
        group,
        1,
        group.barRods.single,
        0,
      );
      expect(item!.text, 'Sep 2 · 1,234');
    });

    test('tooltipText formats date and count', () {
      expect(
        DailyColumnChart.tooltipText(
          DailyCount(date: DateTime.utc(2026, 9, 14), count: 3),
        ),
        'Sep 14 · 3',
      );
    });

    test('the axis has integer gridlines and a round top', () {
      expect(DailyColumnChart.axisFor(_days([0, 2])), (
        maxY: 2.0,
        interval: 1.0,
      ));
      expect(DailyColumnChart.axisFor(_days([0, 0])).maxY, 1.0);
      expect(DailyColumnChart.axisFor(_days([7])), (maxY: 8.0, interval: 2.0));
      expect(DailyColumnChart.axisFor(_days([37])), (
        maxY: 40.0,
        interval: 10.0,
      ));
      expect(DailyColumnChart.axisFor(_days([1234])), (
        maxY: 1500.0,
        interval: 500.0,
      ));
    });

    test('date labels are thinned to at most 8', () {
      expect(DailyColumnChart.labelStepFor(7), 1);
      expect(DailyColumnChart.labelStepFor(30), 4);
      expect(DailyColumnChart.labelStepFor(90), 12);
      for (final n in [1, 7, 15, 30, 60, 90, 101]) {
        expect(
          (n / DailyColumnChart.labelStepFor(n)).ceil(),
          lessThanOrEqualTo(8),
        );
      }
    });
  });
}
