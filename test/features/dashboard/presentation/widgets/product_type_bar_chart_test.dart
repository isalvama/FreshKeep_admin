import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/theme/chart_colors.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/product_type_count.dart';
import 'package:fresh_keep_admin/features/dashboard/presentation/widgets/product_type_bar_chart.dart';
import 'package:fresh_keep_admin/shared/widgets/text_link.dart';

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

void main() {
  group('ProductTypeBarChart', () {
    const counts = [
      ProductTypeCount(productType: 'DAIRY', count: 12),
      ProductTypeCount(productType: 'OTHER_FRESH_PRODUCTS', count: 6),
      ProductTypeCount(productType: 'MEAT', count: 0),
    ];

    testWidgets('one row per type, in the given order, with label and count', (
      tester,
    ) async {
      await _pump(tester, const ProductTypeBarChart(counts: counts));

      final labels = ['Dairy', 'Other fresh products', 'Meat'];
      for (final label in labels) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(
        tester.getTopLeft(find.text('Dairy')).dy,
        lessThan(tester.getTopLeft(find.text('Other fresh products')).dy),
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('bars are proportional to the largest count', (tester) async {
      await _pump(tester, const ProductTypeBarChart(counts: counts));

      double width(String type) =>
          tester.getSize(find.byKey(ValueKey('type-bar-$type'))).width;
      expect(width('DAIRY'), greaterThan(0));
      expect(width('OTHER_FRESH_PRODUCTS'), closeTo(width('DAIRY') / 2, 0.5));
      expect(width('MEAT'), 0);
    });

    testWidgets('bars use the validated series color', (tester) async {
      await _pump(tester, const ProductTypeBarChart(counts: counts));

      final bar = tester.widget<Container>(
        find.byKey(const ValueKey('type-bar-DAIRY')),
      );
      expect((bar.decoration! as BoxDecoration).color, kChartSeriesColor);
    });

    testWidgets('all 17 backend types fit in a scrollable list', (
      tester,
    ) async {
      final many = [
        for (var i = 0; i < 17; i++)
          ProductTypeCount(productType: 'TYPE_$i', count: 17 - i),
      ];
      await _pump(tester, ProductTypeBarChart(counts: many));

      await tester.scrollUntilVisible(find.text('Type 16'), 100);
      expect(find.text('Type 16'), findsOneWidget);
    });

    testWidgets('labels are plain text without onTypeSelected', (tester) async {
      await _pump(tester, const ProductTypeBarChart(counts: counts));

      expect(find.byType(TextLink), findsNothing);
    });

    testWidgets('with onTypeSelected, labels are links that pass the raw '
        'type, by click or keyboard', (tester) async {
      final selected = <String>[];
      await _pump(
        tester,
        ProductTypeBarChart(counts: counts, onTypeSelected: selected.add),
      );

      expect(find.byType(TextLink), findsNWidgets(3));
      await tester.tap(find.text('Other fresh products'));
      await tester.pump();

      // Tab to the first link (Dairy) and press Enter.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected, ['OTHER_FRESH_PRODUCTS', 'DAIRY']);
    });
  });
}
