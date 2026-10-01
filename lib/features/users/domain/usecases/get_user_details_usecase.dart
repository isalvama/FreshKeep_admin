import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_details.dart';
import '../repositories/users_repository.dart';

class GetUserDetailsUseCase {
  final UsersRepository repository;

  const GetUserDetailsUseCase(this.repository);

  Future<Either<AdminFailure, UserDetails>> call(String userId) =>
      repository.getUser(userId);
}
