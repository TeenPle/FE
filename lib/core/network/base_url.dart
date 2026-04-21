import 'package:flutter/foundation.dart';

/// 플랫폼에 따라 적절한 백엔드 base URL을 반환합니다.
/// - Android 에뮬레이터: 10.0.2.2 (호스트 루프백)
/// - Windows/Linux/macOS 데스크톱, iOS 시뮬레이터, 웹: localhost
String get apiBaseUrl {
  if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}
