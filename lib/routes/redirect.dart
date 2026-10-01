import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/shell/presentation/shell_destination.dart';

const kSplashRoute = '/splash';
const kLoginRoute = '/login';
const kHomeRoute = '/dashboard';
const kFromParam = 'from';

/// Where the router should send [location] given the session [state], or
/// null to stay. Kept pure so every rule is unit-tested without widgets.
///
/// - While the session is being checked, everything waits on `/splash`.
/// - Logged out, everything except `/login` goes to `/login`.
/// - Logged in, `/login` and `/splash` go on to where the admin was headed,
///   and unknown paths go to `/dashboard`.
///
/// The original destination travels along as `?from=` so a deep link
/// survives both the splash and the login.
String? resolveRedirect(AuthState state, Uri location) {
  final path = location.path;
  final from = _safeFrom(location.queryParameters[kFromParam]);

  switch (state) {
    case AuthInitial():
      if (path == kSplashRoute) return null;
      return _withFrom(kSplashRoute, _destinationOf(location));
    case Unauthenticated():
      if (path == kLoginRoute) return null;
      if (path == kSplashRoute) return _withFrom(kLoginRoute, from);
      return _withFrom(kLoginRoute, _destinationOf(location));
    case Authenticated():
      if (path == kLoginRoute || path == kSplashRoute) {
        return from ?? kHomeRoute;
      }
      final isKnown = shellDestinations.any((d) => d.path == path);
      return isKnown ? null : kHomeRoute;
  }
}

/// The location worth returning to after login; the bare root isn't.
String? _destinationOf(Uri location) =>
    location.path == '/' || location.path.isEmpty ? null : location.toString();

/// Only in-app paths are honored, so `?from=` can't redirect off-site
/// (`https://…` or protocol-relative `//…`).
String? _safeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  return from;
}

String _withFrom(String route, String? from) => from == null
    ? route
    : Uri(path: route, queryParameters: {kFromParam: from}).toString();
