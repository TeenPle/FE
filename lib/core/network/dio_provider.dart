import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'base_url.dart';

/// 공용 Dio provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  /// 요청 인터셉터
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isAuthPath = options.path.startsWith('/api/auth/');

        if (!isAuthPath) {
          final tokenStorage = ref.read(tokenStorageProvider);
          final accessToken = await tokenStorage.getAccessToken();

          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        }

        handler.next(options);
      },
    ),
  );

  return dio;
});