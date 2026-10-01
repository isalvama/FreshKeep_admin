import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/admin.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/admin_model.dart';
import '../models/login_request_model.dart';

const kInvalidCredentialsMessage = 'Invalid email or password';
const kDisabledAccountMessage = 'This account has been disabled.';
const kNotAdminMessage = "This account doesn't have admin access.";

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<AdminFailure, Admin>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await remoteDataSource.login(
        LoginRequestModel(email: email, password: password),
      );
      final jwt = response.jwtString;
      // Checked before anything is stored: a non-admin token never becomes a session.
      if (!AdminModel.hasAdminRole(jwt)) {
        return const Left(NotAdminFailure(kNotAdminMessage));
      }
      final admin = AdminModel.fromJwt(jwt);
      localDataSource.saveToken(jwt);
      return Right(admin);
    } on DioException catch (e) {
      return Left(switch (mapDioException(e)) {
        UnauthorizedFailure() => const UnauthorizedFailure(
          kInvalidCredentialsMessage,
        ),
        ForbiddenFailure() => const ForbiddenFailure(kDisabledAccountMessage),
        final failure => failure,
      });
    } on FormatException {
      // The backend issued a token we can't read — not something the admin can fix.
      return const Left(ServerFailure(kServerMessage));
    }
  }

  @override
  Admin? currentAdmin() {
    final token = localDataSource.readToken();
    if (token == null) return null;
    try {
      if (_isExpired(token) || !AdminModel.hasAdminRole(token)) {
        localDataSource.clearToken();
        return null;
      }
      return AdminModel.fromJwt(token);
    } on FormatException {
      localDataSource.clearToken();
      return null;
    }
  }

  @override
  void logout() => localDataSource.clearToken();

  // JwtDecoder.isExpired throws NoSuchMethodError (not FormatException) when
  // `exp` is missing, so check for it first.
  static bool _isExpired(String token) {
    if (JwtDecoder.decode(token)['exp'] is! num) {
      throw const FormatException('JWT is missing the "exp" claim');
    }
    return JwtDecoder.isExpired(token);
  }
}
