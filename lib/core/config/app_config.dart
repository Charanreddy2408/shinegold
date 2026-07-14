import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Set to false to use live API at [baseUrl].
  static const bool useMockData = false;

  /// Override at build time:
  /// `--dart-define=API_BASE_URL=http://192.168.1.10:8080`
  ///
  /// Defaults:
  /// - Web / desktop / iOS simulator: `http://127.0.0.1:8080`
  /// - Android emulator: `http://10.0.2.2:8080` (host machine loopback)
  /// - Physical Android device: pass LAN IP via [API_BASE_URL]
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _defaultLocalHost = 'http://127.0.0.1:8080';
  static const String _androidEmulatorHost = 'http://10.0.2.2:8080';

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (!kIsWeb && Platform.isAndroid) return _androidEmulatorHost;
    return _defaultLocalHost;
  }

  static const String logoAsset = 'assets/images/logo.png';

  /// @deprecated Use [logoAsset] for local branding.
  static const String logoUrl = logoAsset;

  static const Duration mockNetworkDelay = Duration.zero;
}
