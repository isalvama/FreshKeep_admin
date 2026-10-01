import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/network/session_expired_notifier.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/login_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/login_bloc.dart';
import 'package:fresh_keep_admin/routes/app_router.dart';
import 'package:go_router/go_router.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/test_route_dependencies.dart';

void main() {
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;
  late GoRouter router;

  Future<void> pumpRouter(
    WidgetTester tester, {
    required String initialLocation,
    bool withStoredAdmin = false,
  }) async {
    notifier = SessionExpiredNotifier();
    final repository = FakeAuthRepository(
      storedAdmin: withStoredAdmin ? kTestAdmin : null,
    );
    authBloc = AuthBloc(
      getCurrentAdminUseCase: GetCurrentAdminUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      sessionExpiredNotifier: notifier,
    );
    loginBloc = LoginBloc(
      loginUseCase: LoginUseCase(repository),
      authBloc: authBloc,
    );
    router = buildAppRouter(
      authBloc,
      initialLocation: initialLocation,
      dependencies: testRouteDependencies(),
    );
    // Same providers as App: the login page needs both blocs.
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: loginBloc),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    authBloc.add(const AppStarted());
    await tester.pumpAndSettle();
  }

  String location() =>
      router.routerDelegate.currentConfiguration.uri.toString();

  tearDown(() async {
    router.dispose();
    await loginBloc.close();
    await authBloc.close();
    await notifier.dispose();
  });

  testWidgets('a logged-out deep link goes to login, then back after login', (
    tester,
  ) async {
    await pumpRouter(tester, initialLocation: '/products?x=1');

    expect(location(), '/login?from=%2Fproducts%3Fx%3D1');

    authBloc.add(const LoggedIn(kTestAdmin));
    await tester.pumpAndSettle();

    expect(location(), '/products?x=1');
    expect(find.text('Coming in SPEC 04'), findsOneWidget);
  });

  testWidgets('a logged-out section sub-page goes to login with it as from', (
    tester,
  ) async {
    await pumpRouter(tester, initialLocation: '/users/abc');

    expect(location(), '/login?from=%2Fusers%2Fabc');
  });

  testWidgets('logging in without from lands on /dashboard', (tester) async {
    await pumpRouter(tester, initialLocation: '/login');

    authBloc.add(const LoggedIn(kTestAdmin));
    await tester.pumpAndSettle();

    // The dashboard then normalizes its missing range (SPEC 02).
    expect(location(), '/dashboard?range=30d');
  });

  testWidgets('a stored session opens the deep link directly', (tester) async {
    await pumpRouter(
      tester,
      initialLocation: '/receipts',
      withStoredAdmin: true,
    );

    expect(location(), '/receipts');
  });

  testWidgets('session expiry sends the admin to login', (tester) async {
    await pumpRouter(
      tester,
      initialLocation: '/products',
      withStoredAdmin: true,
    );

    notifier.notify();
    await tester.pumpAndSettle();

    expect(authBloc.state, const Unauthenticated(sessionExpired: true));
    expect(location(), '/login?from=%2Fproducts');
  });

  testWidgets('logging out leaves no way back to a protected page', (
    tester,
  ) async {
    await pumpRouter(
      tester,
      initialLocation: '/dashboard',
      withStoredAdmin: true,
    );

    authBloc.add(const LoggedOut());
    await tester.pumpAndSettle();
    router.go('/dashboard');
    await tester.pumpAndSettle();

    expect(location(), '/login?from=%2Fdashboard');
  });
}
