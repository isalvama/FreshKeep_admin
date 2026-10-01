import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/products/presentation/pages/product_detail_page.dart';
import '../features/products/presentation/pages/products_list_page.dart';
import '../features/products/presentation/products_list_query.dart';
import '../features/shell/presentation/pages/admin_shell.dart';
import '../features/shell/presentation/pages/section_placeholder_page.dart';
import '../features/shell/presentation/shell_destination.dart';
import '../features/users/presentation/pages/user_detail_page.dart';
import '../features/users/presentation/pages/users_list_page.dart';
import '../features/users/presentation/users_list_query.dart';
import 'redirect.dart';
import 'route_dependencies.dart';

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
/// URL. [dependencies] defaults to the service locator; tests pass fakes.
GoRouter buildAppRouter(
  AuthBloc authBloc, {
  String? initialLocation,
  RouteDependencies? dependencies,
}) {
  final deps = dependencies ?? RouteDependencies.fromServiceLocator();
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
          // The page key ignores the query, so a range change on the
          // dashboard keeps the same page (and DashboardBloc).
          for (final destination in shellDestinations)
            GoRoute(
              path: destination.path,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: switch (destination.path) {
                  kDashboardPath => BlocProvider(
                    create: (_) => deps.dashboardBloc(),
                    child: DashboardPage(query: state.uri.queryParameters),
                  ),
                  kUsersPath => BlocProvider(
                    create: (_) => deps.usersListBloc(),
                    child: UsersListPage(
                      query: state.uri.queryParameters,
                      location: deps.usersListLocation,
                    ),
                  ),
                  kProductsPath => BlocProvider(
                    create: (_) => deps.productsListBloc(),
                    child: ProductsListPage(
                      query: state.uri.queryParameters,
                      location: deps.productsListLocation,
                    ),
                  ),
                  _ => SectionPlaceholderPage(destination: destination),
                },
              ),
            ),
          // A sibling of /users, not a child: as a child, the list page would
          // stay underneath and be rebuilt with the detail URL (no range or
          // page), and its URL normalization would fight the navigation.
          GoRoute(
            path: '$kUsersPath/:userId',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: BlocProvider(
                create: (_) => deps.userDetailBloc(),
                child: UserDetailPage(
                  userId: state.pathParameters['userId']!,
                  location: deps.usersListLocation,
                ),
              ),
            ),
          ),
          // A sibling of /products, for the same reason as /users/:userId.
          GoRoute(
            path: '$kProductsPath/:productId',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: BlocProvider(
                create: (_) => deps.productDetailBloc(),
                child: ProductDetailPage(
                  productId: state.pathParameters['productId']!,
                  location: deps.productsListLocation,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
