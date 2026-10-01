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
import 'package:fresh_keep_admin/shared/metrics/presentation/format.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/widgets/range_bar.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../fakes/fake_users_repository.dart';
import '../../../../fakes/test_route_dependencies.dart';

void main() {
  late FakeUsersRepository repository;
  late UsersListLocation listLocation;
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;
  late GoRouter router;

  setUp(() {
    repository = FakeUsersRepository();
    listLocation = UsersListLocation();
  });

  Future<void> pumpUsers(
    WidgetTester tester, {
    String location = '/users',
  }) async {
    tester.view.physicalSize = const Size(1400, 1800);
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
        users: repository,
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

  String position(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('pagination-position'))).data!;

  IconButton pagerButton(WidgetTester tester, String tooltip) =>
      tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );

  group('URL', () {
    testWidgets('/users is replaced with ?range=30d&page=1 and requested', (
      tester,
    ) async {
      await pumpUsers(tester);

      expect(location(), '/users?range=30d&page=1');
      final (range, page) = repository.listCalls.single;
      expect(range.from, DateTime.utc(2026, 9, 2));
      expect(range.to, DateTime.utc(2026, 10, 1));
      expect(page, 1);
    });

    testWidgets('a deep link keeps its range and page', (tester) async {
      await pumpUsers(tester, location: '/users?range=7d&page=2');

      expect(location(), '/users?range=7d&page=2');
      expect(repository.listCalls.single.$2, 2);
      expect(repository.listCalls.single.$1.from, DateTime.utc(2026, 9, 25));
    });

    testWidgets('an invalid page or range is replaced with the default', (
      tester,
    ) async {
      for (final bad in [
        '/users?range=30d&page=0',
        '/users?range=30d&page=x',
        '/users?range=14d&page=1',
        '/users?from=2026-07-02&to=2026-10-01&page=1', // 91 days
      ]) {
        await pumpUsers(tester, location: bad);

        expect(location(), '/users?range=30d&page=1', reason: bad);
      }
    });

    testWidgets('remembers the list URL for "Back to users"', (tester) async {
      await pumpUsers(tester, location: '/users?range=7d&page=3');

      expect(listLocation.value, '/users?range=7d&page=3');
    });
  });

  group('range', () {
    testWidgets('the range bar is labelled and capped at 90 days', (
      tester,
    ) async {
      await pumpUsers(tester);

      expect(find.text('Registered between'), findsOneWidget);
      for (final label in ['Last 7 days', 'Last 30 days', 'Last 90 days']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(
        tester.widget<RangeBar>(find.byType(RangeBar)).maxLengthInDays,
        90,
      );
    });

    testWidgets('changing the range resets the page to 1', (tester) async {
      await pumpUsers(tester, location: '/users?range=30d&page=3');

      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();

      expect(location(), '/users?range=7d&page=1');
    });
  });

  group('table', () {
    testWidgets('shows email, username and local times for each user', (
      tester,
    ) async {
      await pumpUsers(tester);
      final first = testUsersPage().users[0];
      final second = testUsersPage().users[1];

      expect(find.text(first.email), findsOneWidget);
      expect(find.text(second.username!), findsOneWidget);
      expect(find.text(formatDateTime(second.registeredAt)), findsOneWidget);
      // user-0 has no username, so "—" stands in for it.
      expect(find.text('—'), findsWidgets);
      expect(find.text(formatDateTime(first.lastLoggedAt!)), findsWidgets);
    });

    testWidgets('clicking a row opens that user', (tester) async {
      await pumpUsers(tester);

      await tester.tap(find.text('user1@example.com'));
      await tester.pumpAndSettle();

      expect(location(), '/users/user-1');
    });

    testWidgets('shows the last-login footnote', (tester) async {
      await pumpUsers(tester);

      expect(find.text(kLastLoginFootnote), findsOneWidget);
    });
  });

  group('paging', () {
    testWidgets('page 1 shows 1–30 of 214 with Previous disabled', (
      tester,
    ) async {
      await pumpUsers(tester);

      expect(position(tester), '1–30 of 214');
      expect(pagerButton(tester, 'Previous page').onPressed, isNull);
      expect(pagerButton(tester, 'Next page').onPressed, isNotNull);
    });

    testWidgets('Next moves to page 2: 31–60 of 214', (tester) async {
      await pumpUsers(tester);

      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();

      expect(location(), '/users?range=30d&page=2');
      expect(position(tester), '31–60 of 214');
      expect(repository.listCalls.last.$2, 2);
    });

    testWidgets('Previous moves back a page', (tester) async {
      await pumpUsers(tester, location: '/users?range=30d&page=2');

      await tester.tap(find.byTooltip('Previous page'));
      await tester.pumpAndSettle();

      expect(location(), '/users?range=30d&page=1');
    });

    testWidgets('the last page shows 211–214 with Next disabled', (
      tester,
    ) async {
      await pumpUsers(tester, location: '/users?range=30d&page=8');

      expect(position(tester), '211–214 of 214');
      expect(pagerButton(tester, 'Next page').onPressed, isNull);
    });

    testWidgets('a page past the end offers the first page', (tester) async {
      await pumpUsers(tester, location: '/users?range=30d&page=9');

      expect(find.text('No users on this page'), findsOneWidget);

      await tester.tap(find.text('Go to first page'));
      await tester.pumpAndSettle();

      expect(location(), '/users?range=30d&page=1');
    });
  });

  group('states', () {
    testWidgets('no users in the range shows the empty message', (
      tester,
    ) async {
      repository.usersPage = (_, page) =>
          Right(testUsersPage(page: page, total: 0));

      await pumpUsers(tester);

      expect(find.text('No users registered in this range'), findsOneWidget);
      expect(find.byKey(const Key('pagination-position')), findsNothing);
    });

    testWidgets('a failure shows its message, and Retry reloads the page', (
      tester,
    ) async {
      repository.usersPage = (_, _) => const Left(
        NetworkFailure('Could not reach the server. Please try again.'),
      );

      await pumpUsers(tester, location: '/users?range=30d&page=2');

      expect(
        find.text('Could not reach the server. Please try again.'),
        findsOneWidget,
      );

      repository.usersPage = (_, page) => Right(testUsersPage(page: page));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.listCalls, hasLength(2));
      expect(repository.listCalls.last.$2, 2);
      expect(position(tester), '31–60 of 214');
    });
  });

  testWidgets('at 800px the table scrolls instead of overflowing', (
    tester,
  ) async {
    await pumpUsers(tester);
    tester.view.physicalSize = const Size(800, 1800);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('user0@example.com'), findsOneWidget);
  });
}
