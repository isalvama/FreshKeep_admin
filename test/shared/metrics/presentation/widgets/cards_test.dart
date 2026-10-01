import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/format.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/widgets/chart_card.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/widgets/counts_table.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/widgets/stat_tile.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/section_state.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('formatters', () {
    test('formatCount groups thousands', () {
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
      expect(formatCount(1234), '1,234');
      expect(formatCount(1234567), '1,234,567');
    });

    test('formatShortDate and formatDate', () {
      final day = DateTime.utc(2026, 9, 4);

      expect(formatShortDate(day), 'Sep 4');
      expect(formatDate(day), 'Sep 4, 2026');
    });
  });

  group('StatTile', () {
    testWidgets('loaded shows the label and the formatted total', (
      tester,
    ) async {
      await _pump(
        tester,
        const StatTile(
          label: 'New users',
          status: SectionStatus.loaded,
          value: 1234,
        ),
      );

      expect(find.text('New users'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('loading shows a spinner instead of a value', (tester) async {
      await _pump(
        tester,
        const StatTile(label: 'Receipts', status: SectionStatus.loading),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('failure shows a dash', (tester) async {
      await _pump(
        tester,
        const StatTile(label: 'Receipts', status: SectionStatus.failure),
      );

      expect(find.text('—'), findsOneWidget);
    });
  });

  testWidgets('CountsTable lists one row per entry with formatted counts', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        height: 400,
        child: CountsTable(
          labelHeader: 'Date',
          rows: [('Sep 1, 2026', 0), ('Sep 2, 2026', 1500)],
        ),
      ),
    );

    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Count'), findsOneWidget);
    expect(find.text('Sep 2, 2026'), findsOneWidget);
    expect(find.text('1,500'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  group('ChartCard', () {
    var retries = 0;

    Widget card({
      SectionStatus status = SectionStatus.loaded,
      String? errorMessage,
      bool isEmpty = false,
    }) => ChartCard(
      title: 'Receipts per purchase date',
      subtitle: 'Includes unconfirmed receipts',
      status: status,
      errorMessage: errorMessage,
      onRetry: () => retries++,
      isEmpty: isEmpty,
      emptyMessage: 'No receipts in this range',
      chartBuilder: (_) => const Text('the chart'),
      tableBuilder: (_) => const Text('the table'),
    );

    setUp(() => retries = 0);

    testWidgets('shows the title and subtitle', (tester) async {
      await _pump(tester, card());

      expect(find.text('Receipts per purchase date'), findsOneWidget);
      expect(find.text('Includes unconfirmed receipts'), findsOneWidget);
    });

    testWidgets('loaded shows the chart by default with a toggle', (
      tester,
    ) async {
      await _pump(tester, card());

      expect(find.text('the chart'), findsOneWidget);
      expect(find.text('the table'), findsNothing);
      expect(find.byType(SegmentedButton<ChartView>), findsOneWidget);
    });

    testWidgets('the toggle switches between chart and table', (tester) async {
      await _pump(tester, card());

      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();
      expect(find.text('the table'), findsOneWidget);
      expect(find.text('the chart'), findsNothing);

      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();
      expect(find.text('the chart'), findsOneWidget);
    });

    testWidgets('loading shows a spinner and no toggle', (tester) async {
      await _pump(tester, card(status: SectionStatus.loading));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SegmentedButton<ChartView>), findsNothing);
      expect(find.text('the chart'), findsNothing);
    });

    testWidgets('failure shows the message and Retry calls back', (
      tester,
    ) async {
      await _pump(
        tester,
        card(
          status: SectionStatus.failure,
          errorMessage: 'Could not reach the server. Please try again.',
        ),
      );

      expect(
        find.text('Could not reach the server. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(SegmentedButton<ChartView>), findsNothing);

      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('empty shows the empty message and no toggle', (tester) async {
      await _pump(tester, card(isEmpty: true));

      expect(find.text('No receipts in this range'), findsOneWidget);
      expect(find.text('the chart'), findsNothing);
      expect(find.byType(SegmentedButton<ChartView>), findsNothing);
    });

    testWidgets('the body keeps the same height in every state', (
      tester,
    ) async {
      final heights = <double>[];
      for (final widget in [
        card(),
        card(status: SectionStatus.loading),
        card(status: SectionStatus.failure),
        card(isEmpty: true),
      ]) {
        await _pump(tester, widget);
        heights.add(tester.getSize(find.byType(ChartCard)).height);
      }

      expect(heights.toSet(), hasLength(1));
    });
  });
}
