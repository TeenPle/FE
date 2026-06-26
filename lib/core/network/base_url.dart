/// Returns the backend base URL.
/// - Use --dart-define=API_BASE_URL=https://... to override it.
/// - Defaults to the deployed AWS API for both debug and release builds.
String get apiBaseUrl {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredUrl.isNotEmpty) return configuredUrl;

  return 'https://api.teenple.app';
}

/// WebSocket base URL (http -> ws, https -> wss).
String get wsBaseUrl {
  final http = apiBaseUrl;
  return http
      .replaceFirst('http://', 'ws://')
      .replaceFirst('https://', 'wss://');
}
