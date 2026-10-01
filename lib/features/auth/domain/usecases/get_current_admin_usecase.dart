import '../entities/admin.dart';
import '../repositories/auth_repository.dart';

class GetCurrentAdminUseCase {
  final AuthRepository repository;

  const GetCurrentAdminUseCase(this.repository);

  Admin? call() => repository.currentAdmin();
}
