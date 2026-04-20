import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';

/// 공용 Dio provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
     baseUrl: 'http://10.0.2.2:8080', // 네 환경에 맞게 수정
     //  baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  /// 요청 인터셉터
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final tokenStorage = ref.read(tokenStorageProvider);
        final accessToken = await tokenStorage.getAccessToken();

        /// accessToken이 있으면 Authorization 헤더 자동 첨부
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }

        handler.next(options);
      },
    ),
  );

  return dio;
});