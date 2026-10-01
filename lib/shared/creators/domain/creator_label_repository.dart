import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';

/// Labels for the "Added by …" filter chip, shared by the lists that filter
/// by creator (products, receipts).
abstract class CreatorLabelRepository {
  /// The email of the user (`users.id`).
  Future<Either<AdminFailure, String>> getCreatorEmail(String userId);
}
