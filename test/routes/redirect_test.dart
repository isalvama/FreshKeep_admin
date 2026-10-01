import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fresh_keep_admin/routes/redirect.dart';

import '../fakes/fake_auth_repository.dart';

String? _redirect(AuthState state, String location) =>
    resolveRedirect(state, Uri.parse(location));

void main() {
  const initial = AuthInitial();
  const loggedOut = Unauthenticated();
  const expired = Unauthenticated(sessionExpired: true);
  const loggedIn = Authenticated(kTestAdmin);

  group('while the session is being checked', () {
    test('stays on /splash', () {
      expect(_redirect(initial, '/splash'), isNull);
      expect(_redirect(initial, '/splash?from=%2Fusers'), isNull);
    });

    test('sends any other location to /splash, keeping it as from', () {
      expect(_redirect(initial, '/users?x=1'), '/splash?from=%2Fusers%3Fx%3D1');
      expect(_redirect(initial, '/login'), '/splash?from=%2Flogin');
    });

    test('does not keep the bare root as from', () {
      expect(_redirect(initial, '/'), '/splash');
    });
  });

  group('when logged out', () {
    test('stays on /login', () {
      expect(_redirect(loggedOut, '/login'), isNull);
      expect(_redirect(loggedOut, '/login?from=%2Fusers'), isNull);
      expect(_redirect(expired, '/login'), isNull);
    });

    test('sends a protected location to /login with it as from', () {
      expect(
        _redirect(loggedOut, '/users?x=1'),
        '/login?from=%2Fusers%3Fx%3D1',
      );
      expect(_redirect(expired, '/products'), '/login?from=%2Fproducts');
    });

    test('sends /splash to /login, carrying its from along', () {
      expect(_redirect(loggedOut, '/splash'), '/login');
      expect(
        _redirect(loggedOut, '/splash?from=%2Fusers%3Fx%3D1'),
        '/login?from=%2Fusers%3Fx%3D1',
      );
    });

    test('sends a section sub-page to /login with it as from', () {
      expect(_redirect(loggedOut, '/users/abc'), '/login?from=%2Fusers%2Fabc');
    });

    test('sends the bare root to /login without from', () {
      expect(_redirect(loggedOut, '/'), '/login');
    });
  });

  group('when logged in', () {
    test('stays on every shell section', () {
      for (final path in [
        '/dashboard',
        '/users',
        '/products',
        '/receipts',
        '/admins',
      ]) {
        expect(_redirect(loggedIn, path), isNull, reason: path);
      }
      expect(_redirect(loggedIn, '/users?x=1'), isNull);
    });

    test('sends /login and /splash to from', () {
      expect(_redirect(loggedIn, '/login?from=%2Fusers%3Fx%3D1'), '/users?x=1');
      expect(_redirect(loggedIn, '/splash?from=%2Freceipts'), '/receipts');
    });

    test('sends /login and /splash without from to /dashboard', () {
      expect(_redirect(loggedIn, '/login'), '/dashboard');
      expect(_redirect(loggedIn, '/splash'), '/dashboard');
    });

    test('stays on pages under a shell section', () {
      expect(_redirect(loggedIn, '/users/abc'), isNull);
      expect(_redirect(loggedIn, '/users/abc?tab=x'), isNull);
      expect(_redirect(loggedIn, '/receipts/r-1'), isNull);
    });

    test('sends look-alikes of a section to /dashboard', () {
      for (final path in ['/userszzz', '/nope/users', '/users/', '/dash']) {
        expect(_redirect(loggedIn, path), '/dashboard', reason: path);
      }
    });

    test('sends unknown paths to /dashboard', () {
      expect(_redirect(loggedIn, '/'), '/dashboard');
      expect(_redirect(loggedIn, '/nope'), '/dashboard');
      expect(_redirect(loggedIn, '/Users'), '/dashboard');
    });

    test('ignores a from that is not an in-app path', () {
      for (final from in [
        'https://evil.example.com',
        '//evil.example.com',
        'users',
      ]) {
        final login = Uri(path: '/login', queryParameters: {'from': from});
        expect(
          _redirect(loggedIn, login.toString()),
          '/dashboard',
          reason: from,
        );
      }
    });
  });
}
