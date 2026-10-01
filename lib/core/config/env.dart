class Env {
  /// Defaults to the backend's dev compose port. Override with
  /// `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8082',
  );
}
