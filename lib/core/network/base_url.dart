import 'package:flutter/foundation.dart';

/// 플랫폼/빌드 모드에 따라 적절한 백엔드 base URL을 반환합니다.
/// - 릴리즈 빌드: --dart-define=API_BASE_URL=https://... 으로 주입, 기본값 teenple.app
/// - 디버그 Android 에뮬레이터: 10.0.2.2 (호스트 루프백)
/// - 디버그 Windows/Linux/macOS/iOS 시뮬레이터: localhost
String get apiBaseUrl {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredUrl.isNotEmpty) return configuredUrl;

  if (kReleaseMode) {
    return 'https://api.teenple.app';
  }
  if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
    const isPhysical = bool.fromEnvironment(
      'USE_PHYSICAL',
      defaultValue: false,
    );
    return isPhysical ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

/// WebSocket base URL (http → ws, https → wss)
String get wsBaseUrl {
  final http = apiBaseUrl;
  return http
      .replaceFirst('http://', 'ws://')
      .replaceFirst('https://', 'wss://');
}
