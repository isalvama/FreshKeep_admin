import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/session_storage.dart';

class AuthLocalDataSource {
  final SessionStorage sessionStorage;

  const AuthLocalDataSource(this.sessionStorage);

  String? readToken() => sessionStorage.read(StorageKeys.jwt);

  void saveToken(String jwt) => sessionStorage.write(StorageKeys.jwt, jwt);

  void clearToken() => sessionStorage.delete(StorageKeys.jwt);
}
