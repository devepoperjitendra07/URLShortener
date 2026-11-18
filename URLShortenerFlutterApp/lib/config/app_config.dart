/// Centralised runtime configuration.
///
/// Every value can be overridden at build/run time with `--dart-define`, so no
/// environment-specific host or key is baked into the source. Examples:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8082/api   # Android emulator
///   flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api \
///                     --dart-define=SDK_KEY=git_live_xxxxx
class AppConfig {
  /// Backend REST base, including the `/api` context path.
  /// Defaults to localhost (works for web, desktop and the iOS simulator).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8082/api',
  );

  /// SDK key for the deferred-deep-link tracker (demo default; override in prod).
  static const String sdkKey = String.fromEnvironment(
    'SDK_KEY',
    defaultValue: 'sdk_test_12345',
  );

  /// Builds the public short URL for a redirect code.
  static String shortUrl(String code) => '$apiBaseUrl/r/$code';
}