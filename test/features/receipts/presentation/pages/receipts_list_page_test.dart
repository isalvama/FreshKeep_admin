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
import 'package:fresh_keep_admin/features/receipts/presentation/pages/receipts_list_page.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/receipts_list_location.dart';
import 'package:fresh_keep_admin/routes/app_router.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/format.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/widgets/range_bar.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../fakes/fake_receipts_repository.dart';
import '../../../../fakes/test_route_dependencies.dart';

const _creator = kTestReceiptCreatorId;

void main() {
  late FakeReceiptsRepository repository;
  late ReceiptsListLocation listLocation;
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;
  late GoRouter router;

  setUp(() {
    repository = FakeReceiptsRepository();
    listLocation = ReceiptsListLocation();
  });

  Future<void> pumpReceipts(
    WidgetTester tester, {
    String location = '/receipts',
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
        receipts: repository,
        receiptsListLocation: listLocation,
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
    testWidgets('/receipts is replaced with the defaults and requested', (
      tester,
    ) async {
      await pumpReceipts(tester);

      expect(location(), '/receipts?range=30d&page=1');
      final (range, creatorId, page) = repository.listCalls.single;
      expect(range.from, DateTime.utc(2026, 9, 2));
      expect(range.to, DateTime.utc(2026, 10, 1));
      expect(creatorId, isNull);
      expect(page, 1);
    });

    testWidgets('a deep link keeps its range, creator and page', (
      tester,
    ) async {
      const url = '/receipts?range=7d&creatorId=$_creator&page=2';
      await pumpReceipts(tester, location: url);

      expect(location(), url);
      final (range, creatorId, page) = repository.listCalls.single;
      expect(range.from, DateTime.utc(2026, 9, 25));
      expect((creatorId, page), (_creator, 2));
    });

    testWidgets('invalid values are dropped one by one, valid ones kept', (
      tester,
    ) async {
      for (final (bad, fixed) in [
        (
          '/receipts?range=14d&creatorId=$_creator&page=2',
          '/receipts?range=30d&creatorId=$_creator&page=2',
        ),
        (
          '/receipts?from=2026-06-22&to=2026-10-01&page=1', // 101 days
          '/receipts?range=30d&page=1',
        ),
        (
          '/receipts?range=7d&creatorId=abc&page=0',
          '/receipts?range=7d&page=1',
        ),
      ]) {
        await pumpReceipts(tester, location: bad);

        expect(location(), fixed, reason: bad);
      }
    });

    testWidgets('remembers the list URL for "Back to receipts"', (
      tester,
    ) async {
      await pumpReceipts(tester, location: '/receipts?range=90d&page=3');

      expect(listLocation.value, '/receipts?range=90d&page=3');
    });
  });

  group('range and creator', () {
    testWidgets('the range bar is labelled and capped at 100 days', (
      tester,
    ) async {
      await pumpReceipts(tester);

      expect(find.text('Purchased between'), findsOneWidget);
      expect(
        tester.widget<RangeBar>(find.byType(RangeBar)).maxLengthInDays,
        100,
      );
    });

    testWidgets('a new range resets the page and keeps the creator', (
      tester,
    ) async {
      await pumpReceipts(
        tester,
        location: '/receipts?range=30d&creatorId=$_creator&page=3',
      );

      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();

      expect(location(), '/receipts?range=7d&creatorId=$_creator&page=1');
    });

    testWidgets('a creator filter shows its email; ✕ removes it', (
      tester,
    ) async {
      await pumpReceipts(
        tester,
        location: '/receipts?range=7d&creatorId=$_creator&page=2',
      );

      expect(find.text('Added by alice@example.com'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove creator filter'));
      await tester.pumpAndSettle();

      expect(location(), '/receipts?range=7d&page=1');
      expect(find.byKey(const Key('creator-chip')), findsNothing);
    });

    testWidgets('a chip that cannot be labelled shows a short id; the list '
        'still loads', (tester) async {
      repository.creatorEmail = const Left(
        ServerFailure('Something went wrong.'),
      );
      await pumpReceipts(
        tester,
        location: '/receipts?range=30d&creatorId=$_creator&page=1',
      );

      expect(find.text('Added by 3f2a9c1e…'), findsOneWidget);
      expect(find.text('Store 000'), findsOneWidget);
    });
  });

  group('table', () {
    testWidgets('shows purchase date, store, creator, space and count', (
      tester,
    ) async {
      await pumpReceipts(tester);

      expect(find.text(kUnconfirmedReceiptsNote), findsOneWidget);
      expect(find.text('Sep 30, 2026'), findsWidgets);
      expect(find.text('Store 000'), findsOneWidget);
      expect(find.text('user0@example.com'), findsOneWidget);
      expect(find.text('Kitchen'), findsWidgets);
      // Every 3rd row has no creator, space or store: rows 2, 5, … 29.
      expect(find.text(kMissingValue), findsNWidgets(10 * 3));
    });

    testWidgets('clicking a row opens that receipt', (tester) async {
      await pumpReceipts(tester);

      await tester.tap(find.text('Store 001'));
      await tester.pumpAndSettle();

      expect(location(), '/receipts/receipt-1');
    });
  });

  group('paging', () {
    testWidgets('page 1 shows 1–30 of 75 with Previous disabled', (
      tester,
    ) async {
      await pumpReceipts(tester);

      expect(position(tester), '1–30 of 75');
      expect(pagerButton(tester, 'Previous page').onPressed, isNull);
      expect(pagerButton(tester, 'Next page').onPressed, isNotNull);
    });

    testWidgets('Next moves to page 2, keeping range and creator', (
      tester,
    ) async {
      await pumpReceipts(
        tester,
        location: '/receipts?range=7d&creatorId=$_creator&page=1',
      );

      // The chip makes the page taller than the test window.
      await tester.ensureVisible(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();

      expect(location(), '/receipts?range=7d&creatorId=$_creator&page=2');
      expect(position(tester), '31–60 of 75');
    });

    testWidgets('the last page shows 61–75 with Next disabled', (tester) async {
      await pumpReceipts(tester, location: '/receipts?range=30d&page=3');

      expect(position(tester), '61–75 of 75');
      expect(pagerButton(tester, 'Next page').onPressed, isNull);
    });

    testWidgets('a page past the end offers the first page', (tester) async {
      await pumpReceipts(tester, location: '/receipts?range=7d&page=9');

      expect(find.text(kNoReceiptsOnPageMessage), findsOneWidget);

      await tester.tap(find.text('Go to first page'));
      await tester.pumpAndSettle();

      expect(location(), '/receipts?range=7d&page=1');
    });
  });

  group('states', () {
    testWidgets('no receipts in the range shows the empty message', (
      tester,
    ) async {
      repository.receiptsPage = (_, _, page) =>
          Right(testReceiptsPage(page: page, total: 0));
      await pumpReceipts(tester);

      expect(find.text(kNoReceiptsInRangeMessage), findsOneWidget);
      expect(find.text('Go to first page'), findsNothing);
    });

    testWidgets('a failure shows its message, and Retry reloads the page', (
      tester,
    ) async {
      repository.receiptsPage = (_, _, _) => const Left(
        NetworkFailure('Could not reach the server. Please try again.'),
      );
      await pumpReceipts(tester, location: '/receipts?range=30d&page=2');

      expect(
        find.text('Could not reach the server. Please try again.'),
        findsOneWidget,
      );

      repository.receiptsPage = (_, _, page) =>
          Right(testReceiptsPage(page: page));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.listCalls, hasLength(2));
      expect(repository.listCalls.last.$3, 2);
      expect(position(tester), '31–60 of 75');
    });
  });

  testWidgets('at 800px the table scrolls instead of overflowing', (
    tester,
  ) async {
    await pumpReceipts(
      tester,
      location: '/receipts?range=30d&creatorId=$_creator&page=1',
    );
    tester.view.physicalSize = const Size(800, 1800);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Store 000'), findsOneWidget);
  });
}
