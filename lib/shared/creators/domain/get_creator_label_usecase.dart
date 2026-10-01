import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import 'creator_label_repository.dart';

/// The email shown on a "Added by …" filter chip.
class GetCreatorLabelUseCase {
  final CreatorLabelRepository repository;

  const GetCreatorLabelUseCase(this.repository);

  Future<Either<AdminFailure, String>> call(String userId) =>
      repository.getCreatorEmail(userId);
}
