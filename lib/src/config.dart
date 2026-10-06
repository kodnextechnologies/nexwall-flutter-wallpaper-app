/// Compile-time configuration.
///
/// The API key is injected at build time and is never stored in source:
///
///   flutter run --dart-define=NEXWALL_API_KEY=your_key_here
///
/// or keep it in an untracked JSON file and use
///   flutter run --dart-define-from-file=env.json
class AppConfig {
  static const String apiKey = String.fromEnvironment('NEXWALL_API_KEY');

  static const String defaultBaseUrl =
      'https://nexwall.kodnextech.com/api/developer/v1';

  /// Override with --dart-define=NEXWALL_BASE_URL=https://your-proxy/...
  /// to route requests through your own backend proxy.
  static const String baseUrl = String.fromEnvironment(
    'NEXWALL_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  /// When a proxy is used, the proxy holds the key and the app needs none.
  static bool get usesProxy => baseUrl != defaultBaseUrl;

  /// Wallpapers requested per page (the API allows 1-100, default 50).
  static const int pageSize = 30;

  static bool get hasApiKey => apiKey.isNotEmpty;
}
