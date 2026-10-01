/// Tab-scoped key/value storage. Synchronous because the browser's
/// `sessionStorage` is.
///
/// Logic depends on this interface only, so tests (which run on the Dart VM,
/// without browser APIs) can use an in-memory fake.
abstract class SessionStorage {
  String? read(String key);

  void write(String key, String value);

  void delete(String key);
}
