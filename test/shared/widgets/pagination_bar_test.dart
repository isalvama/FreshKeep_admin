import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/shared/widgets/pagination_bar.dart';

void main() {
  Future<List<int>> pump(
    WidgetTester tester, {
    int? total,
    String? label,
    bool hasPrevious = true,
    bool hasNext = true,
  }) async {
    final requested = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginationBar(
            page: 2,
            firstIndex: 31,
            lastIndex: 60,
            total: total,
            label: label,
            hasPrevious: hasPrevious,
            hasNext: hasNext,
            onPageChanged: requested.add,
          ),
        ),
      ),
    );
    return requested;
  }

  String position(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('pagination-position'))).data!;

  IconButton button(WidgetTester tester, String tooltip) => tester.widget(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(IconButton),
    ),
  );

  testWidgets('shows "of N" when the total is known', (tester) async {
    await pump(tester, total: 1214);
    expect(position(tester), '31–60 of 1,214');
  });

  testWidgets('shows a label and no total when there is none', (tester) async {
    await pump(tester, label: 'Products');
    expect(position(tester), 'Products 31–60');
  });

  testWidgets('Previous and Next request the neighbouring pages', (
    tester,
  ) async {
    final requested = await pump(tester);
    await tester.tap(find.byTooltip('Previous page'));
    await tester.tap(find.byTooltip('Next page'));
    expect(requested, [1, 3]);
  });

  testWidgets('disabled buttons at the ends', (tester) async {
    await pump(tester, hasPrevious: false, hasNext: false);
    expect(button(tester, 'Previous page').onPressed, isNull);
    expect(button(tester, 'Next page').onPressed, isNull);
  });
}
