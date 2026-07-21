import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Set to false to use live API at [baseUrl].
  static const bool useMockData = false;

  /// Override at build time:
  /// `--dart-define=API_BASE_URL=http://192.168.1.10:8000`
  ///
  /// Local dev port **8000** — matches `fastapi dev` / `fastapi run` default
  /// and backend `pyproject.toml` `[tool.fastapi].port`.
  ///
  /// Defaults:
  /// - Web / desktop / iOS simulator: `http://127.0.0.1:8000`
  /// - Android emulator: `http://10.0.2.2:8000` (host machine loopback)
  /// - Physical Android device: pass LAN IP via [API_BASE_URL]
  static const int apiPort = 8000;

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _defaultLocalHost = 'http://127.0.0.1:8000';
  static const String _androidEmulatorHost = 'http://10.0.2.2:8000';

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (!kIsWeb && Platform.isAndroid) return _androidEmulatorHost;
    return _defaultLocalHost;
  }

  static const String logoAsset = 'assets/images/logo.png';

  /// @deprecated Use [logoAsset] for local branding.
  static const String logoUrl = logoAsset;

  static const Duration mockNetworkDelay = Duration.zero;

  /// Pre-fills login when no saved employee ID exists (debug / local dev).
  /// Override: `--dart-define=DEFAULT_EMPLOYEE_ID=EXEC002`
  static const String defaultEmployeeId = String.fromEnvironment(
    'DEFAULT_EMPLOYEE_ID',
    defaultValue: 'EXEC001',
  );
}
