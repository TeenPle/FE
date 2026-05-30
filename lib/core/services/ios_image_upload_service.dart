import 'dart:io';

import 'package:flutter/services.dart';

class NormalizedUploadImage {
  final String path;
  final String name;
  final Uint8List bytes;

  const NormalizedUploadImage({
    required this.path,
    required this.name,
    required this.bytes,
  });
}

abstract class IosImageUploadService {
  static const _channel = MethodChannel('teenple/media');

  static bool hasAllowedExtension(String path, Set<String> allowed) {
    return allowed.contains(path.split('.').last.toLowerCase());
  }

  static Future<NormalizedUploadImage?> normalizeHeic(String path) async {
    if (!Platform.isIOS || !_isHeic(path)) return null;

    final result = await _channel.invokeMapMethod<String, Object?>(
      'normalizeImageFile',
      {'path': path, 'name': _fileName(path)},
    );
    if (result == null) return null;

    final normalizedPath = result['path'] as String? ?? '';
    final bytes = result['bytes'] as Uint8List? ?? Uint8List(0);
    if (normalizedPath.isEmpty || bytes.isEmpty) return null;

    return NormalizedUploadImage(
      path: normalizedPath,
      name: result['name'] as String? ?? _fileName(normalizedPath),
      bytes: bytes,
    );
  }

  static bool _isHeic(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ext == 'heic' || ext == 'heif';
  }

  static String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;
}
