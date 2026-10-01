import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/network/session_expired_notifier.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../fakes/fake_auth_repository.dart';

/// Lets queued events and stream notifications run.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeAuthRepository repository;
  late SessionExpiredNotifier notifier;
  late AuthBloc bloc;
  late List<AuthState> emitted;

  void build({bool withStoredAdmin = false}) {
    repository = FakeAuthRepository(
      storedAdmin: withStoredAdmin ? kTestAdmin : null,
    );
    notifier = SessionExpiredNotifier();
    bloc = AuthBloc(
      getCurrentAdminUseCase: GetCurrentAdminUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      sessionExpiredNotifier: notifier,
    );
    emitted = [];
    bloc.stream.listen(emitted.add);
  }

  tearDown(() async {
    await bloc.close();
    await notifier.dispose();
  });

  test('starts in AuthInitial', () {
    build();

    expect(bloc.state, const AuthInitial());
  });

  group('AppStarted', () {
    test('emits Authenticated when a valid session is stored', () async {
      build(withStoredAdmin: true);

      bloc.add(const AppStarted());
      await _settle();

      expect(emitted, [const Authenticated(kTestAdmin)]);
    });

    test(
      'emits Unauthenticated (not expired) when there is no session',
      () async {
        build();

        bloc.add(const AppStarted());
        await _settle();

        expect(emitted, [const Unauthenticated()]);
      },
    );
  });

  test('LoggedIn emits Authenticated with the admin', () async {
    build();

    bloc.add(const LoggedIn(kTestAdmin));
    await _settle();

    expect(emitted, [const Authenticated(kTestAdmin)]);
  });

  test('LoggedOut clears the session and emits Unauthenticated', () async {
    build(withStoredAdmin: true);
    bloc.add(const AppStarted());
    await _settle();

    bloc.add(const LoggedOut());
    await _settle();

    expect(repository.logoutCalls, 1);
    expect(emitted.last, const Unauthenticated());
  });

  group('session expiry', () {
    test(
      'a notifier signal while authenticated clears the session and emits Unauthenticated(sessionExpired: true)',
      () async {
        build(withStoredAdmin: true);
        bloc.add(const AppStarted());
        await _settle();

        notifier.notify();
        await _settle();

        expect(repository.logoutCalls, 1);
        expect(emitted.last, const Unauthenticated(sessionExpired: true));
      },
    );

    test('several signals at once log out only once', () async {
      build(withStoredAdmin: true);
      bloc.add(const AppStarted());
      await _settle();

      notifier
        ..notify()
        ..notify()
        ..notify();
      await _settle();

      expect(repository.logoutCalls, 1);
      expect(emitted, [
        const Authenticated(kTestAdmin),
        const Unauthenticated(sessionExpired: true),
      ]);
    });

    test('a signal while not authenticated is ignored', () async {
      build();
      bloc.add(const AppStarted());
      await _settle();

      notifier.notify();
      await _settle();

      expect(repository.logoutCalls, 0);
      expect(emitted, [const Unauthenticated()]);
    });

    test('closing the bloc stops listening to the notifier', () async {
      build(withStoredAdmin: true);
      await bloc.close();

      expect(() => notifier.notify(), returnsNormally);
      await _settle();
      expect(repository.logoutCalls, 0);
    });
  });
}
