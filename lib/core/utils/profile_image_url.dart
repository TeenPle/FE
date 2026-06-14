import '../network/base_url.dart';

String? normalizeProfileImageUrl(String? rawUrl) {
  final value = rawUrl?.trim();
  if (value == null || value.isEmpty || value == 'default_profile.png') {
    return null;
  }

  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return value;
  }

  if (value.startsWith('//')) {
    final baseScheme = Uri.parse(apiBaseUrl).scheme;
    return '$baseScheme:$value';
  }

  return Uri.parse(apiBaseUrl).resolve(value).toString();
}

String? readProfileImageUrl(Map<String, dynamic> json) {
  const keys = [
    'authorProfileImageUrl',
    'profileImageUrl',
    'authorProfileUrl',
    'profileUrl',
  ];

  for (final key in keys) {
    final value = json[key];
    if (value is String) {
      final normalized = normalizeProfileImageUrl(value);
      if (normalized != null) return normalized;
    }
  }

  return null;
}
