import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Runtime configuration for the frontend.
///
/// Override any of these from the command line:
///
///     flutter run --dart-define=API_HOST=192.168.1.42 \
///                 --dart-define=API_PORT=8000 \
///                 --dart-define=USE_MOCKS=false
class AppConfig {
  /// Host of the Laravel backend (no scheme, no port, no path).
  /// Defaults pick the right value for the current platform:
  ///   - Android emulator → 10.0.2.2   (host PC's 127.0.0.1 from inside the emu)
  ///   - everything else → 127.0.0.1   (iOS sim / desktop / web)
  /// A physical phone must pass --dart-define=API_HOST=<your PC's LAN IP>
  /// and the backend must be started with --host=0.0.0.0.
  static String get apiHost {
    const override = String.fromEnvironment('API_HOST');
    if (override.isNotEmpty) return override;
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) return '10.0.2.2';
      } catch (_) {
        // Platform can throw on unsupported targets — fall through.
      }
    }
    return '127.0.0.1';
  }

  static String get apiPort {
    const override = String.fromEnvironment('API_PORT');
    return override.isEmpty ? '8000' : override;
  }

  static String get apiScheme {
    const override = String.fromEnvironment('API_SCHEME');
    return override.isEmpty ? 'http' : override;
  }

  /// Full base URL, e.g. `http://10.0.2.2:8000`.
  static String get baseUrl => '$apiScheme://$apiHost:$apiPort';

  /// When `false` (default), cubits must surface real errors instead of
  /// silently falling back to `MockData`. Flip to `true` for offline demos:
  ///     flutter run --dart-define=USE_MOCKS=true
  static const bool useMocks =
      bool.fromEnvironment('USE_MOCKS', defaultValue: false);

  /// When `true` (default in debug), logs network errors to the console so
  /// connection/auth failures are visible during development.
  static const bool logNetworkErrors =
      bool.fromEnvironment('LOG_NETWORK_ERRORS', defaultValue: kDebugMode);
}
