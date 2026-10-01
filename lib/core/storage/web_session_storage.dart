import 'package:web/web.dart' as web;

import 'session_storage.dart';

/// Backed by `window.sessionStorage`: survives reloads, cleared when the tab
/// closes. Only importable on web — never import it from tests.
class WebSessionStorage implements SessionStorage {
  const WebSessionStorage();

  @override
  String? read(String key) => web.window.sessionStorage.getItem(key);

  @override
  void write(String key, String value) =>
      web.window.sessionStorage.setItem(key, value);

  @override
  void delete(String key) => web.window.sessionStorage.removeItem(key);
}
