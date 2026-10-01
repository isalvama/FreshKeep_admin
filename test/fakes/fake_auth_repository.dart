import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/auth/domain/entities/admin.dart';
import 'package:fresh_keep_admin/features/auth/domain/repositories/auth_repository.dart';

import 'jwt_factory.dart';

const kTestAdmin = Admin(
  accountId: kTestAccountId,
  adminId: kTestAdminId,
  email: kTestEmail,
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.storedAdmin, this.loginResult});

  /// What [currentAdmin] returns; cleared by [logout].
  Admin? storedAdmin;

  /// What [login] resolves to. When null, [login] waits on [loginCompleter],
  /// so tests can observe the in-flight state.
  Either<AdminFailure, Admin>? loginResult;
  final loginCompleter = Completer<Either<AdminFailure, Admin>>();

  final List<(String, String)> loginCalls = [];
  int logoutCalls = 0;

  @override
  Future<Either<AdminFailure, Admin>> login(String email, String password) {
    loginCalls.add((email, password));
    final result = loginResult;
    return result != null ? Future.value(result) : loginCompleter.future;
  }

  @override
  Admin? currentAdmin() => storedAdmin;

  @override
  void logout() {
    logoutCalls++;
    storedAdmin = null;
  }
}
