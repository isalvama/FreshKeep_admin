import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/guard_request.dart';
import '../domain/creator_label_repository.dart';
import 'creator_label_remote_datasource.dart';

class CreatorLabelRepositoryImpl implements CreatorLabelRepository {
  final CreatorLabelRemoteDataSource remoteDataSource;

  const CreatorLabelRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<AdminFailure, String>> getCreatorEmail(String userId) =>
      guardRequest(() => remoteDataSource.getUserEmail(userId));
}
