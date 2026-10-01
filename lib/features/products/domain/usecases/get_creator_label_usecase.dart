import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/products_repository.dart';

class GetCreatorLabelUseCase {
  final ProductsRepository repository;

  const GetCreatorLabelUseCase(this.repository);

  Future<Either<AdminFailure, String>> call(String userId) =>
      repository.getCreatorEmail(userId);
}
