import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/session_expired_notifier.dart';
import 'package:fresh_keep_admin/features/auth/domain/entities/admin.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/login_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/login_bloc.dart';

import '../../../../fakes/fake_auth_repository.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeAuthRepository repository;
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;
  late List<LoginState> emitted;

  void build({Either<AdminFailure, Admin>? loginResult}) {
    repository = FakeAuthRepository(loginResult: loginResult);
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
    emitted = [];
    loginBloc.stream.listen(emitted.add);
  }

  tearDown(() async {
    await loginBloc.close();
    await authBloc.close();
    await notifier.dispose();
  });

  const submitted = LoginSubmitted(
    email: 'admin@freshkeep.com',
    password: 'Password1',
  );

  test('passes the credentials to the use case', () async {
    build(loginResult: const Right(kTestAdmin));

    loginBloc.add(submitted);
    await _settle();

    expect(repository.loginCalls, [('admin@freshkeep.com', 'Password1')]);
  });

  test('emits Submitting then Success and logs the admin in', () async {
    build(loginResult: const Right(kTestAdmin));

    loginBloc.add(submitted);
    await _settle();

    expect(emitted, [const LoginSubmitting(), const LoginSuccess(kTestAdmin)]);
    expect(authBloc.state, const Authenticated(kTestAdmin));
  });

  test('stays in Submitting while the request is in flight', () async {
    build();

    loginBloc.add(submitted);
    await _settle();

    expect(loginBloc.state, const LoginSubmitting());
  });

  test(
    'emits Submitting then Failure with the failure message and does not log in',
    () async {
      build(
        loginResult: const Left(
          NotAdminFailure("This account doesn't have admin access."),
        ),
      );

      loginBloc.add(submitted);
      await _settle();

      expect(emitted, [
        const LoginSubmitting(),
        const LoginFailure("This account doesn't have admin access."),
      ]);
      expect(authBloc.state, const AuthInitial());
    },
  );
}
