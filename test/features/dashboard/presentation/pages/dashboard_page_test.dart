import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/session_expired_notifier.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/login_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/login_bloc.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/daily_count.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/product_type_count.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/widgets/chart_card.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/widgets/stat_tile.dart';
import 'package:fresh_keep_admin/routes/app_router.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../fakes/fake_dashboard_repository.dart';
import '../../../../fakes/test_route_dependencies.dart';

void main() {
  late FakeDashboardRepository repository;
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;
  late GoRouter router;

  setUp(() {
    repository = FakeDashboardRepository()
      ..registrations = Right([
        DailyCount(date: DateTime.utc(2026, 9, 30), count: 2),
        DailyCount(date: DateTime.utc(2026, 10, 1), count: 3),
      ])
      ..products = Right([
        DailyCount(date: DateTime.utc(2026, 10, 1), count: 1234),
      ])
      ..receipts = Right([
        DailyCount(date: DateTime.utc(2026, 9, 28), count: 4),
      ])
      ..productTypes = const Right([
        ProductTypeCount(productType: 'DAIRY', count: 9),
        ProductTypeCount(productType: 'MEAT', count: 3),
      ]);
  });

  Future<void> pumpDashboard(
    WidgetTester tester, {
    String location = '/dashboard',
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final authRepository = FakeAuthRepository(storedAdmin: kTestAdmin);
    notifier = SessionExpiredNotifier();
    authBloc = AuthBloc(
      getCurrentAdminUseCase: GetCurrentAdminUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      sessionExpiredNotifier: notifier,
    )..add(const AppStarted());
    loginBloc = LoginBloc(
      loginUseCase: LoginUseCase(authRepository),
      authBloc: authBloc,
    );
    router = buildAppRouter(
      authBloc,
      initialLocation: location,
      dependencies: testRouteDependencies(dashboard: repository),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: loginBloc),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    router.dispose();
    await loginBloc.close();
    await authBloc.close();
    await notifier.dispose();
  });

  String location() =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Finder card(String section) => find.byKey(ValueKey('chart-card-$section'));

  int columnsIn(WidgetTester tester, String section) => tester
      .widget<BarChart>(
        find.descendant(of: card(section), matching: find.byType(BarChart)),
      )
      .data
      .barGroups
      .length;

  String tileValue(WidgetTester tester, String label) {
    final tile = find.ancestor(
      of: find.text(label),
      matching: find.byType(StatTile),
    );
    return tester.widget<StatTile>(tile).value.toString();
  }

  group('range and URL', () {
    testWidgets('/dashboard is replaced with ?range=30d and selects it', (
      tester,
    ) async {
      await pumpDashboard(tester);

      expect(location(), '/dashboard?range=30d');
      expect(columnsIn(tester, 'registrations'), 30);
      expect(find.text('Sep 2, 2026 – Oct 1, 2026'), findsOneWidget);
    });

    testWidgets('?range=7d shows 7 columns per daily chart', (tester) async {
      await pumpDashboard(tester, location: '/dashboard?range=7d');

      expect(location(), '/dashboard?range=7d');
      for (final section in ['registrations', 'products', 'receipts']) {
        expect(columnsIn(tester, section), 7, reason: section);
      }
    });

    testWidgets('a custom from/to shows one column per day', (tester) async {
      // The shared fixtures fall outside Sep 1–15; without activity in range
      // the card would (correctly) show its empty state instead of a chart.
      repository.products = Right([
        DailyCount(date: DateTime.utc(2026, 9, 5), count: 2),
      ]);

      await pumpDashboard(
        tester,
        location: '/dashboard?from=2026-09-01&to=2026-09-15',
      );

      expect(columnsIn(tester, 'products'), 15);
      expect(find.text('Sep 1, 2026 – Sep 15, 2026'), findsOneWidget);
    });

    testWidgets('an invalid range is replaced with ?range=30d', (tester) async {
      for (final bad in [
        '/dashboard?from=2026-13-01&to=2026-09-15',
        '/dashboard?range=14d',
        '/dashboard?from=2026-09-15&to=2026-09-01',
        '/dashboard?from=2026-06-01&to=2026-10-01',
      ]) {
        await pumpDashboard(tester, location: bad);

        expect(location(), '/dashboard?range=30d', reason: bad);
      }
    });

    testWidgets('requests send the resolved range', (tester) async {
      await pumpDashboard(tester, location: '/dashboard?range=7d');

      final ranges = repository.calls
          .where((c) => c.$2 != null)
          .map((c) => c.$2!)
          .toSet();
      expect(ranges, hasLength(1));
      expect(ranges.single.from, DateTime.utc(2026, 9, 25));
      expect(ranges.single.to, DateTime.utc(2026, 10, 1));
    });

    testWidgets('choosing a preset updates the URL and the charts', (
      tester,
    ) async {
      await pumpDashboard(tester);

      await tester.tap(find.text('Last 90 days'));
      await tester.pumpAndSettle();

      expect(location(), '/dashboard?range=90d');
      expect(columnsIn(tester, 'receipts'), 90);
    });
  });

  group('content', () {
    testWidgets('tiles show the range totals', (tester) async {
      await pumpDashboard(tester);

      expect(tileValue(tester, 'New users'), '5');
      expect(tileValue(tester, 'Products added'), '1234');
      expect(tileValue(tester, 'Receipts'), '4');
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('shows the four charts with their titles and subtitles', (
      tester,
    ) async {
      await pumpDashboard(tester);

      for (final text in [
        'New users per day',
        'Products added per day',
        'Includes deleted products',
        'Receipts per purchase date',
        'Includes unconfirmed receipts',
        'Products by type',
        'All time · excludes deleted products',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text('Dairy'), findsOneWidget);
    });

    testWidgets('the table view lists the same values', (tester) async {
      await pumpDashboard(tester, location: '/dashboard?range=7d');

      await tester.tap(
        find.descendant(
          of: card('registrations'),
          matching: find.text('Table'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: card('registrations'),
          matching: find.text('Sep 30, 2026'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card('registrations'),
          matching: find.text('Sep 25, 2026'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a metric with no activity shows its empty message and 0', (
      tester,
    ) async {
      repository.registrations = const Right([]);

      await pumpDashboard(tester);

      expect(find.text('No new users in this range'), findsOneWidget);
      expect(tileValue(tester, 'New users'), '0');
    });
  });

  group('states', () {
    testWidgets('a failing section shows Retry while the others render', (
      tester,
    ) async {
      repository.receipts = const Left(
        NetworkFailure('Could not reach the server. Please try again.'),
      );

      await pumpDashboard(tester);

      expect(
        find.descendant(
          of: card('receipts'),
          matching: find.text('Could not reach the server. Please try again.'),
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(columnsIn(tester, 'registrations'), 30);
      expect(find.text('Dairy'), findsOneWidget);

      repository.receipts = const Right([]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsNothing);
      expect(repository.callsTo('receipts'), 2);
      expect(repository.callsTo('registrations'), 1);
    });

    testWidgets('a range change refetches the daily sections only', (
      tester,
    ) async {
      await pumpDashboard(tester);

      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();

      expect(repository.callsTo('registrations'), 2);
      expect(repository.callsTo('productTypes'), 1);
    });

    testWidgets('Refresh refetches all four', (tester) async {
      await pumpDashboard(tester);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      for (final endpoint in [
        'registrations',
        'products',
        'receipts',
        'productTypes',
      ]) {
        expect(repository.callsTo(endpoint), 2, reason: endpoint);
      }
    });
  });

  testWidgets('at 800px the cards stack in one column without overflow', (
    tester,
  ) async {
    await pumpDashboard(tester);
    tester.view.physicalSize = const Size(800, 3000);
    await tester.pumpAndSettle();

    final first = tester.getTopLeft(card('registrations'));
    final second = tester.getTopLeft(card('products'));
    expect(second.dx, first.dx);
    expect(second.dy, greaterThan(first.dy));
    expect(find.byType(ChartCard), findsNWidgets(4));
  });

  testWidgets('a product type label opens the products list filtered by it', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.byKey(const ValueKey('type-link-MEAT')));
    await tester.pumpAndSettle();

    expect(location(), '/products?sort=name_asc&type=MEAT&page=1');
  });
}
