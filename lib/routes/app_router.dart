import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/shell/presentation/pages/admin_shell.dart';
import '../features/shell/presentation/pages/section_placeholder_page.dart';
import '../features/shell/presentation/shell_destination.dart';
import 'redirect.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// [initialLocation] is for tests; in the browser the router starts from the
/// URL.
GoRouter buildAppRouter(AuthBloc authBloc, {String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) => resolveRedirect(authBloc.state, state.uri),
    routes: [
      GoRoute(
        path: kSplashRoute,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: kLoginRoute,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          // Later specs replace a section's placeholder with its real page.
          for (final destination in shellDestinations)
            GoRoute(
              path: destination.path,
              pageBuilder: (context, state) => NoTransitionPage(
                child: SectionPlaceholderPage(destination: destination),
              ),
            ),
        ],
      ),
    ],
  );
}
