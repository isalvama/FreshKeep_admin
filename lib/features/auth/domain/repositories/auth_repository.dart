import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin.dart';

abstract class AuthRepository {
  Future<Either<AdminFailure, Admin>> login(String email, String password);

  /// The admin of the stored session, or null when there is no token or it is
  /// expired, malformed, or not an admin's (in which case it is cleared).
  Admin? currentAdmin();

  void logout();
}
