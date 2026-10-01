import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../entities/users_page.dart';
import '../repositories/users_repository.dart';

class GetUsersUseCase {
  final UsersRepository repository;

  const GetUsersUseCase(this.repository);

  Future<Either<AdminFailure, UsersPage>> call(
    DateRange registeredBetween, {
    required int page,
  }) => repository.getUsers(registeredBetween, page: page);
}
