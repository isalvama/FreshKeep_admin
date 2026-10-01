import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/network/session_expired_notifier.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/login_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/login_bloc.dart';
import 'package:fresh_keep_admin/features/shell/presentation/shell_destination.dart';
import 'package:fresh_keep_admin/routes/app_router.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../fakes/fake_dashboard_repository.dart';
import '../../../../fakes/jwt_factory.dart';

void main() {
  late FakeAuthRepository repository;
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;
  late GoRouter router;

  /// Pumps the full app router, logged in, in a window [width] pixels wide.
  Future<void> pumpShell(
    WidgetTester tester, {
    double width = 1200,
    String initialLocation = '/dashboard',
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = FakeAuthRepository(storedAdmin: kTestAdmin);
    notifier = SessionExpiredNotifier();
    authBloc = AuthBloc(
      getCurrentAdminUseCase: GetCurrentAdminUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      sessionExpiredNotifier: notifier,
    )..add(const AppStarted());
    loginBloc = LoginBloc(
      loginUseCase: LoginUseCase(repository),
      authBloc: authBloc,
    );
    router = buildAppRouter(
      authBloc,
      initialLocation: initialLocation,
      dashboardBlocFactory: buildTestDashboardBloc,
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
  NavigationRail rail(WidgetTester tester) =>
      tester.widget<NavigationRail>(find.byType(NavigationRail));
  Finder inRail(Finder finder) =>
      find.descendant(of: find.byType(NavigationRail), matching: finder);

  group('layout', () {
    testWidgets('at 1200px the rail shows labels for every section', (
      tester,
    ) async {
      await pumpShell(tester, width: 1200);

      expect(rail(tester).extended, isTrue);
      for (final label in [
        'Dashboard',
        'Users',
        'Products',
        'Receipts',
        'Admins',
      ]) {
        expect(inRail(find.text(label)), findsOneWidget, reason: label);
      }
    });

    testWidgets('at 1000px the rail is still labelled', (tester) async {
      await pumpShell(tester, width: 1000);

      expect(rail(tester).extended, isTrue);
    });

    testWidgets('at 800px the rail shows icons only, with tooltips', (
      tester,
    ) async {
      await pumpShell(tester, width: 800);

      expect(rail(tester).extended, isFalse);
      expect(
        rail(tester).labelType ?? NavigationRailLabelType.none,
        NavigationRailLabelType.none,
      );
      for (final destination in shellDestinations) {
        expect(
          inRail(find.byTooltip(destination.label)),
          findsOneWidget,
          reason: destination.label,
        );
      }
    });

    testWidgets('at 600px the shell is still shown', (tester) async {
      await pumpShell(tester, width: 600);

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('below 600px only the larger-screen notice is shown', (
      tester,
    ) async {
      await pumpShell(tester, width: 500);

      expect(find.text('Please use a larger screen'), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Logout'), findsNothing);
    });
  });

  group('navigation', () {
    testWidgets('selecting a rail item goes to its path and highlights it', (
      tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(inRail(find.text('Users')));
      await tester.pumpAndSettle();

      expect(location(), '/users');
      expect(rail(tester).selectedIndex, 1);
    });

    testWidgets('loading a section URL directly highlights its item', (
      tester,
    ) async {
      await pumpShell(tester, initialLocation: '/receipts');

      expect(rail(tester).selectedIndex, 3);
    });

    testWidgets('each unbuilt section shows its spec placeholder', (
      tester,
    ) async {
      await pumpShell(tester);

      // The dashboard is built (SPEC 02); the rest are placeholders.
      for (final (path, spec) in [
        ('/users', '03'),
        ('/products', '04'),
        ('/receipts', '05'),
        ('/admins', '06'),
      ]) {
        router.go(path);
        await tester.pumpAndSettle();

        expect(find.text('Coming in SPEC $spec'), findsOneWidget, reason: path);
      }
    });
  });

  group('top bar', () {
    testWidgets('shows the logged-in admin email', (tester) async {
      await pumpShell(tester);

      expect(
        tester.widget<Text>(find.byKey(const Key('shell-admin-email'))).data,
        kTestEmail,
      );
    });

    testWidgets('Logout clears the session and lands on /login', (
      tester,
    ) async {
      await pumpShell(tester, initialLocation: '/users');

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(repository.logoutCalls, 1);
      expect(authBloc.state, const Unauthenticated());
      expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
      expect(find.byType(NavigationRail), findsNothing);

      router.go('/users');
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsNothing);
    });
  });
}
