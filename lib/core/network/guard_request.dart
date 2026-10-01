import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import 'dio_failure_mapper.dart';

/// Runs a backend call for a repository: a failed request maps through
/// [mapDioException]; a response we can't read (wrong shape, missing field)
/// is a [ServerFailure] — not something the admin can fix.
Future<Either<AdminFailure, T>> guardRequest<T>(
  Future<T> Function() call,
) async {
  try {
    return Right(await call());
  } on DioException catch (e) {
    return Left(mapDioException(e));
  } on FormatException {
    return const Left(ServerFailure(kServerMessage));
  } on TypeError {
    return const Left(ServerFailure(kServerMessage));
  }
}
