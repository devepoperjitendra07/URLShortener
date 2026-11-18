/// Centralised runtime configuration for the admin console.
///
/// Override at build/run time with `--dart-define`, e.g.:
///   flutter run -d chrome --dart-define=API_BASE_URL=https://api.example.com/api
class AppConfig {
  /// Backend REST base, including the `/api` context path.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8082/api',
  );
}