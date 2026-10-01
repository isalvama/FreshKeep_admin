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
import 'package:fresh_keep_admin/features/users/presentation/users_list_location.dart';
import 'package:fresh_keep_admin/features/users/presentation/widgets/last_login_footnote.dart';
import 'package:fresh_keep_admin/routes/app_router.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/daily_count.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/format.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../fakes/fake_dashboard_repository.dart';
import '../../../../fakes/fake_users_repository.dart';
import '../../../../fakes/test_route_dependencies.dart';

void main() {
  late FakeUsersRepository users;
  late FakeDashboardRepository metrics;
  late UsersListLocation listLocation;
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;
  late GoRouter router;

  setUp(() {
    users = FakeUsersRepository();
    metrics = FakeDashboardRepository()
      ..products = Right([
        DailyCount(date: DateTime.utc(2026, 9, 30), count: 4),
      ])
      ..receipts = Right([
        DailyCount(date: DateTime.utc(2026, 9, 28), count: 1),
      ]);
    listLocation = UsersListLocation();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    String location = '/users/user-1',
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
      dependencies: testRouteDependencies(
        dashboard: metrics,
        users: users,
        usersListLocation: listLocation,
      ),
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

  testWidgets('requests the user and both activity series with creatorId', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(users.detailCalls, ['user-1']);
    expect(metrics.creatorIds, ['user-1', 'user-1']);
    expect(metrics.calls.map((c) => c.$2!.from).toSet(), {
      DateTime.utc(2026, 9, 2),
    });
  });

  testWidgets('a URL-encoded id reaches the backend decoded', (tester) async {
    await pumpDetail(tester, location: '/users/a%20b');

    expect(users.detailCalls, ['a b']);
  });

  testWidgets('keeps the Users rail item highlighted', (tester) async {
    await pumpDetail(tester);

    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
  });

  group('profile', () {
    testWidgets('shows email, roles, username, times and the footnote', (
      tester,
    ) async {
      await pumpDetail(tester);
      final user = testUserDetails();

      expect(find.text('user1@example.com'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'User'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Admin'), findsOneWidget);
      expect(find.text('user1'), findsOneWidget);
      expect(find.text(formatDateTime(user.registeredAt)), findsOneWidget);
      expect(find.text(formatDateTime(user.lastLoggedAt!)), findsOneWidget);
      expect(find.text(kLastLoginFootnote), findsOneWidget);
    });
  });

  group('spaces', () {
    testWidgets('lists the space names', (tester) async {
      await pumpDetail(tester);

      expect(find.text('Spaces'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);
    });

    testWidgets('says when the user is in no space', (tester) async {
      users.details = Right(testUserDetails(spaces: const []));

      await pumpDetail(tester);

      expect(find.text('Not a member of any space'), findsOneWidget);
    });
  });

  group('receipts', () {
    testWidgets('lists store, purchase date and created, newest first', (
      tester,
    ) async {
      await pumpDetail(tester);
      final receipts = testUserDetails().receipts;
      final newer = receipts.firstWhere((r) => r.id == 'r-2');
      final older = receipts.firstWhere((r) => r.id == 'r-1');

      expect(find.text('Includes unconfirmed receipts'), findsWidgets);
      expect(find.text('SuperMart'), findsOneWidget);
      expect(find.text(formatDate(older.purchaseDate)), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(formatDateTime(newer.createdAt))).dy,
        lessThan(
          tester.getTopLeft(find.text(formatDateTime(older.createdAt))).dy,
        ),
      );
    });

    testWidgets('says when the user has no receipts', (tester) async {
      users.details = Right(testUserDetails(receipts: const []));

      await pumpDetail(tester);

      expect(find.text('No receipts yet'), findsOneWidget);
    });
  });

  group('activity', () {
    testWidgets('two charts of 30 days, labelled and with their semantics', (
      tester,
    ) async {
      await pumpDetail(tester);

      for (final section in ['productsActivity', 'receiptsActivity']) {
        final chart = tester.widget<BarChart>(
          find.descendant(of: card(section), matching: find.byType(BarChart)),
        );
        expect(chart.data.barGroups, hasLength(30), reason: section);
      }
      expect(find.text('Products added per day'), findsOneWidget);
      expect(
        find.text('Last 30 days · Includes deleted products'),
        findsOneWidget,
      );
      expect(find.text('Receipts per purchase date'), findsOneWidget);
      expect(
        find.text('Last 30 days · Includes unconfirmed receipts'),
        findsOneWidget,
      );
    });

    testWidgets('a failing series shows Retry only in its card', (
      tester,
    ) async {
      metrics.receipts = const Left(ServerFailure('Something went wrong.'));

      await pumpDetail(tester);

      expect(
        find.descendant(
          of: card('receiptsActivity'),
          matching: find.text('Retry'),
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('user1@example.com'), findsOneWidget);

      metrics.receipts = const Right([]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(metrics.callsTo('receipts'), 2);
      expect(metrics.callsTo('products'), 1);
      expect(users.detailCalls, hasLength(1));
      expect(find.text('No receipts in the last 30 days'), findsOneWidget);
    });
  });

  testWidgets('a details failure offers Retry while activity still shows', (
    tester,
  ) async {
    users.details = const Left(
      NetworkFailure('Could not reach the server. Please try again.'),
    );

    await pumpDetail(tester);

    expect(
      find.text('Could not reach the server. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(BarChart), findsNWidgets(2));

    users.details = Right(testUserDetails());
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('user1@example.com'), findsOneWidget);
  });

  testWidgets('an unknown user shows "User not found" and the back link', (
    tester,
  ) async {
    users.details = const Left(
      ValidationFailure('User with id nope does not exist.'),
    );

    await pumpDetail(tester, location: '/users/nope');

    expect(find.text('User not found'), findsOneWidget);
    expect(find.text('Back to users'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
    expect(find.text('Spaces'), findsNothing);
  });

  group('back link', () {
    testWidgets('returns to the remembered list URL', (tester) async {
      listLocation.remember('/users?range=7d&page=3');

      await pumpDetail(tester);
      await tester.tap(find.text('Back to users'));
      await tester.pumpAndSettle();

      expect(location(), '/users?range=7d&page=3');
    });

    testWidgets('goes to the default list without a remembered URL', (
      tester,
    ) async {
      await pumpDetail(tester);
      await tester.tap(find.text('Back to users'));
      await tester.pumpAndSettle();

      expect(location(), '/users?range=30d&page=1');
    });

    testWidgets('list → user → back round-trips the range and page', (
      tester,
    ) async {
      await pumpDetail(tester, location: '/users?range=7d&page=2');

      await tester.tap(find.text('user31@example.com'));
      await tester.pumpAndSettle();
      expect(location(), '/users/user-31');

      await tester.tap(find.text('Back to users'));
      await tester.pumpAndSettle();
      expect(location(), '/users?range=7d&page=2');
    });
  });

  testWidgets('at 800px the sections stack without overflow', (tester) async {
    await pumpDetail(tester);
    tester.view.physicalSize = const Size(800, 3000);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Spaces')).dy,
      greaterThan(tester.getTopLeft(find.text('user1@example.com')).dy),
    );
  });
}
