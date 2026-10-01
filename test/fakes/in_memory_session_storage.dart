import 'package:fresh_keep_admin/core/storage/session_storage.dart';

class InMemorySessionStorage implements SessionStorage {
  final Map<String, String> values;

  InMemorySessionStorage([Map<String, String>? initial])
    : values = {...?initial};

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;

  @override
  void delete(String key) => values.remove(key);
}
