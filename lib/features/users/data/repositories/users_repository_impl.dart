import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/guard_request.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../../domain/entities/user_details.dart';
import '../../domain/entities/users_page.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_datasource.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remoteDataSource;

  const UsersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<AdminFailure, UsersPage>> getUsers(
    DateRange registeredBetween, {
    required int page,
  }) => guardRequest(
    () => remoteDataSource.getUsers(registeredBetween, page: page),
  );

  @override
  Future<Either<AdminFailure, UserDetails>> getUser(String userId) =>
      guardRequest(() => remoteDataSource.getUser(userId));
}
