import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/dashboard_range.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/date_range.dart';
import 'package:fresh_keep_admin/features/dashboard/presentation/widgets/dashboard_range_bar.dart';

final _today = DateTime(2026, 10, 1, 9, 30);

class _FakePicker {
  DateTimeRange? answer;
  final calls = <({DateTimeRange initial, DateTime first, DateTime last})>[];

  Future<DateTimeRange?> call(
    BuildContext context, {
    required DateTimeRange initialRange,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    calls.add((initial: initialRange, first: firstDate, last: lastDate));
    return answer;
  }
}

void main() {
  late List<DashboardRange> changes;
  late int refreshes;
  late _FakePicker picker;

  setUp(() {
    changes = [];
    refreshes = 0;
    picker = _FakePicker();
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    DashboardRange range = const PresetRange(RangePreset.last30),
    DateRangePicker? pick,
  }) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardRangeBar(
            range: range,
            resolvedRange: range.resolve(_today),
            today: _today,
            onRangeChanged: changes.add,
            onRefresh: () => refreshes++,
            pickDateRange: pick ?? picker.call,
          ),
        ),
      ),
    );
  }

  SegmentedButton<RangePreset> presets(WidgetTester tester) =>
      tester.widget<SegmentedButton<RangePreset>>(
        find.byType(SegmentedButton<RangePreset>),
      );

  Future<void> pickCustom(
    WidgetTester tester,
    DateTime from,
    DateTime to,
  ) async {
    picker.answer = DateTimeRange(start: from, end: to);
    await tester.tap(find.byKey(const Key('custom-range-button')));
    await tester.pumpAndSettle();
  }

  group('presets', () {
    testWidgets('lists the three presets and selects the current one', (
      tester,
    ) async {
      await pumpBar(tester);

      for (final label in ['Last 7 days', 'Last 30 days', 'Last 90 days']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(presets(tester).selected, {RangePreset.last30});
      expect(find.text('Custom…'), findsOneWidget);
    });

    testWidgets('selecting a preset reports it', (tester) async {
      await pumpBar(tester);

      await tester.tap(find.text('Last 7 days'));
      await tester.pump();

      expect(changes, [const PresetRange(RangePreset.last7)]);
    });

    testWidgets('shows the dates the preset covers', (tester) async {
      await pumpBar(tester);

      expect(find.text('Sep 2, 2026 – Oct 1, 2026'), findsOneWidget);
    });
  });

  group('custom range', () {
    testWidgets('opens the picker on the current dates, ending today', (
      tester,
    ) async {
      await pumpBar(tester);

      await pickCustom(tester, DateTime(2026, 9, 1), DateTime(2026, 9, 15));

      final call = picker.calls.single;
      expect(call.initial.start, DateTime(2026, 9, 2));
      expect(call.initial.end, DateTime(2026, 10, 1));
      expect(call.last, DateTime(2026, 10, 1));
    });

    testWidgets('a pick within 100 days is reported as a CustomRange', (
      tester,
    ) async {
      await pumpBar(tester);

      await pickCustom(tester, DateTime(2026, 9, 1), DateTime(2026, 9, 15));

      expect(changes, [
        CustomRange(
          DateRange(from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 15)),
        ),
      ]);
    });

    testWidgets('exactly 100 days (to − from) is accepted', (tester) async {
      await pumpBar(tester);

      await pickCustom(tester, DateTime(2026, 6, 23), DateTime(2026, 10, 1));

      expect(changes, hasLength(1));
      expect(find.text(kRangeTooLongMessage), findsNothing);
    });

    testWidgets('101 days is rejected with a message and not applied', (
      tester,
    ) async {
      await pumpBar(tester);

      await pickCustom(tester, DateTime(2026, 6, 22), DateTime(2026, 10, 1));

      expect(changes, isEmpty);
      expect(find.text('Choose a range of at most 100 days.'), findsOneWidget);
    });

    testWidgets('dismissing the picker changes nothing', (tester) async {
      await pumpBar(tester);

      await tester.tap(find.byKey(const Key('custom-range-button')));
      await tester.pumpAndSettle();

      expect(picker.calls, hasLength(1));
      expect(changes, isEmpty);
    });

    testWidgets(
      'while custom, no preset is selected and the button shows the range',
      (tester) async {
        await pumpBar(
          tester,
          range: CustomRange(
            DateRange(from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 15)),
          ),
        );

        expect(presets(tester).selected, isEmpty);
        expect(find.text('Sep 1, 2026 – Sep 15, 2026'), findsOneWidget);
        expect(find.text('Custom…'), findsNothing);
      },
    );

    testWidgets('the custom button reopens the picker while custom', (
      tester,
    ) async {
      await pumpBar(
        tester,
        range: CustomRange(
          DateRange(from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 15)),
        ),
      );

      await pickCustom(tester, DateTime(2026, 9, 3), DateTime(2026, 9, 4));

      expect(picker.calls.single.initial.start, DateTime(2026, 9, 1));
      expect(changes, hasLength(1));
    });

    testWidgets('the real picker does not allow dates after today', (
      tester,
    ) async {
      await pumpBar(tester, pick: showMaterialDateRangePicker);

      await tester.tap(find.byKey(const Key('custom-range-button')));
      await tester.pumpAndSettle();

      final dialog = tester.widget<DateRangePickerDialog>(
        find.byType(DateRangePickerDialog),
      );
      expect(dialog.lastDate, DateTime(2026, 10, 1));
    });
  });

  testWidgets('Refresh reports a refresh', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.text('Refresh'));

    expect(refreshes, 1);
  });
}
