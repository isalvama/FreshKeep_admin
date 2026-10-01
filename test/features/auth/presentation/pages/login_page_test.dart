import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/dio_failure_mapper.dart';
import 'package:fresh_keep_admin/core/network/session_expired_notifier.dart';
import 'package:fresh_keep_admin/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/login_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/login_bloc.dart';
import 'package:fresh_keep_admin/features/auth/presentation/pages/login_page.dart';

import '../../../../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;

  Future<void> pumpLoginPage(
    WidgetTester tester, {
    FakeAuthRepository? withRepository,
  }) async {
    repository = withRepository ?? FakeAuthRepository();
    notifier = SessionExpiredNotifier();
    authBloc = AuthBloc(
      getCurrentAdminUseCase: GetCurrentAdminUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      sessionExpiredNotifier: notifier,
    );
    loginBloc = LoginBloc(
      loginUseCase: LoginUseCase(repository),
      authBloc: authBloc,
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: loginBloc),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
  }

  tearDown(() async {
    await loginBloc.close();
    await authBloc.close();
    await notifier.dispose();
  });

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Finder submitButton() => find.byType(FilledButton);

  Future<void> submit(
    WidgetTester tester, {
    String email = '',
    String password = '',
  }) async {
    await tester.enterText(field('Email'), email);
    await tester.enterText(field('Password'), password);
    await tester.tap(submitButton());
    await tester.pump();
  }

  group('validation on submit', () {
    testWidgets('empty fields show required errors and send nothing', (
      tester,
    ) async {
      await pumpLoginPage(tester);

      await submit(tester);

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(repository.loginCalls, isEmpty);
    });

    testWidgets('a malformed email shows an error and sends nothing', (
      tester,
    ) async {
      await pumpLoginPage(tester);

      await submit(tester, email: 'not-an-email', password: 'Password1');

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(repository.loginCalls, isEmpty);
    });

    testWidgets('a password outside 8–20 characters shows an error', (
      tester,
    ) async {
      await pumpLoginPage(tester);

      for (final password in ['short', 'a' * 21]) {
        await submit(tester, email: 'admin@freshkeep.com', password: password);

        expect(
          find.text('Password must be between 8 and 20 characters'),
          findsOneWidget,
          reason: password,
        );
      }
      expect(repository.loginCalls, isEmpty);
    });

    testWidgets('errors do not show before submitting', (tester) async {
      await pumpLoginPage(tester);

      await tester.enterText(field('Email'), 'not-an-email');
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsNothing);
    });
  });

  testWidgets('valid input logs in with the trimmed email', (tester) async {
    await pumpLoginPage(
      tester,
      withRepository: FakeAuthRepository(loginResult: const Right(kTestAdmin)),
    );

    await submit(
      tester,
      email: '  admin@freshkeep.com ',
      password: 'Password1',
    );
    await tester.pumpAndSettle();

    expect(repository.loginCalls, [('admin@freshkeep.com', 'Password1')]);
    expect(authBloc.state, const Authenticated(kTestAdmin));
  });

  testWidgets('pressing Enter in the password field submits', (tester) async {
    await pumpLoginPage(
      tester,
      withRepository: FakeAuthRepository(loginResult: const Right(kTestAdmin)),
    );

    await tester.enterText(field('Email'), 'admin@freshkeep.com');
    await tester.enterText(field('Password'), 'Password1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repository.loginCalls, hasLength(1));
  });

  testWidgets('while in flight the button is disabled and shows a spinner', (
    tester,
  ) async {
    await pumpLoginPage(tester);

    await submit(tester, email: 'admin@freshkeep.com', password: 'Password1');
    await tester.pump();

    final button = tester.widget<FilledButton>(submitButton());
    expect(button.onPressed, isNull);
    expect(
      find.descendant(
        of: submitButton(),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    repository.loginCompleter.complete(const Right(kTestAdmin));
    await tester.pumpAndSettle();
  });

  group('failures are shown in a SnackBar', () {
    for (final failure in <AdminFailure>[
      const NotAdminFailure(kNotAdminMessage),
      const UnauthorizedFailure(kInvalidCredentialsMessage),
      const ForbiddenFailure(kDisabledAccountMessage),
      const ValidationFailure('email: must be a well-formed email address'),
      const ServerFailure(kServerMessage),
      const NetworkFailure(kNetworkMessage),
    ]) {
      testWidgets(failure.runtimeType.toString(), (tester) async {
        await pumpLoginPage(
          tester,
          withRepository: FakeAuthRepository(loginResult: Left(failure)),
        );

        await submit(
          tester,
          email: 'admin@freshkeep.com',
          password: 'Password1',
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(failure.message),
          ),
          findsOneWidget,
        );
        expect(authBloc.state, isNot(isA<Authenticated>()));
        expect(
          tester.widget<FilledButton>(submitButton()).onPressed,
          isNotNull,
        );
      });
    }
  });

  group('session-expired banner', () {
    testWidgets('shows after the session expired', (tester) async {
      await pumpLoginPage(
        tester,
        withRepository: FakeAuthRepository(storedAdmin: kTestAdmin),
      );
      authBloc.add(const AppStarted());
      await tester.pumpAndSettle();

      notifier.notify();
      await tester.pumpAndSettle();

      expect(find.text(kSessionExpiredMessage), findsOneWidget);
    });

    testWidgets('does not show after a normal logout or a fresh start', (
      tester,
    ) async {
      await pumpLoginPage(
        tester,
        withRepository: FakeAuthRepository(storedAdmin: kTestAdmin),
      );
      authBloc.add(const AppStarted());
      await tester.pumpAndSettle();
      authBloc.add(const LoggedOut());
      await tester.pumpAndSettle();

      expect(find.text(kSessionExpiredMessage), findsNothing);
    });
  });

  testWidgets('has no registration link', (tester) async {
    await pumpLoginPage(tester);

    expect(
      find.textContaining(RegExp('regist|sign up', caseSensitive: false)),
      findsNothing,
    );
  });
}
