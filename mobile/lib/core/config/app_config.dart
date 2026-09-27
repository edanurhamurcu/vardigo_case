import 'dart:io' show Platform;

/// Runtime configuration, overridable with --dart-define.
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api
///   flutter run --dart-define=FRAME=true   // draws the iPhone bezel from the spec
abstract final class AppConfig {
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Renders the app inside the 390×844 phone frame described in the design spec.
  static const bool showPhoneFrame = bool.fromEnvironment('FRAME');

  /// Android emulator reaches the host machine via 10.0.2.2, iOS simulator via localhost.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    return Platform.isAndroid ? 'http://10.0.2.2:3000/api' : 'http://localhost:3000/api';
  }

  /// The API returns asset paths like "/assets/photos/merve.png"; they are served
  /// from the same host, outside the /api prefix.
  static String assetUrl(String path) {
    final origin = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$origin$path';
  }
}
