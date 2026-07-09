class AppConfig {
  AppConfig._();

  /// Set to false to use live API at [baseUrl].
  static const bool useMockData = false;

  /// Use 127.0.0.1 with adb reverse (confirmed working on this emulator).
  static const String baseUrl = 'http://127.0.0.1:8010';

  static const String logoAsset = 'assets/images/logo.png';

  /// @deprecated Use [logoAsset] for local branding.
  static const String logoUrl = logoAsset;

  static const Duration mockNetworkDelay = Duration.zero;
}
