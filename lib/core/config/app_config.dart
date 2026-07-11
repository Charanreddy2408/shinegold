class AppConfig {
  AppConfig._();

  /// Set to false to use live API at [baseUrl].
  static const bool useMockData = false;

  /// Override at build time: `--dart-define=API_BASE_URL=https://api.example.com`
  /// For Android emulator with local backend: `adb reverse tcp:8080 tcp:8080`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  static const String logoAsset = 'assets/images/logo.png';

  /// @deprecated Use [logoAsset] for local branding.
  static const String logoUrl = logoAsset;

  static const Duration mockNetworkDelay = Duration.zero;
}
