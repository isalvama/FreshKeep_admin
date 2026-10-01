import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<Either<AdminFailure, Admin>> call(String email, String password) {
    return repository.login(email, password);
  }
}
