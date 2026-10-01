import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../entities/user_details.dart';
import '../entities/users_page.dart';

/// Users per page, the backend's default.
const kUsersPageSize = 30;

abstract class UsersRepository {
  /// Users registered in [registeredBetween], newest first; [page] is
  /// 1-based.
  Future<Either<AdminFailure, UsersPage>> getUsers(
    DateRange registeredBetween, {
    required int page,
  });

  /// A missing user (or a malformed id) fails with [ValidationFailure]: the
  /// backend answers 400 for both.
  Future<Either<AdminFailure, UserDetails>> getUser(String userId);
}
