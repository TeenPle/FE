import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../auth/auth_session_provider.dart';
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

  // 동시에 여러 요청이 401을 받아도 refresh를 한 번만 호출하기 위한 lock
  bool isRefreshing = false;
  Completer<String?>? refreshCompleter;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isAuthPath = options.path.startsWith('/api/auth/');

        if (!isAuthPath) {
          final token = ref.read(authSessionProvider).accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        handler.next(options);
      },

      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final isAuthPath = error.requestOptions.path.startsWith('/api/auth/');
        final isRetry = error.requestOptions.extra['_retry'] == true;

        if (statusCode == 401 && !isAuthPath && !isRetry) {
          // ── 다른 요청이 refresh 중이면 결과를 기다렸다가 재시도 ──
          if (isRefreshing) {
            final newToken = await refreshCompleter!.future;
            if (newToken != null) {
              try {
                handler.resolve(await _retry(dio, error.requestOptions, newToken));
              } catch (_) {
                handler.next(error);
              }
            } else {
              handler.next(error);
            }
            return;
          }

          isRefreshing = true;
          refreshCompleter = Completer<String?>();

          String? newAccessToken;

          try {
            final storage = ref.read(tokenStorageProvider);
            final refreshToken = ref.read(authSessionProvider).refreshToken
                ?? await storage.getRefreshToken();

            if (refreshToken == null) throw Exception('no refresh token');

            // refresh 호출은 인터셉터 없는 별도 Dio (무한루프 방지)
            final plainDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
            final refreshResponse = await plainDio.post(
              '/api/auth/refresh',
              data: {'refreshToken': refreshToken},
            );

            final result = refreshResponse.data['result'] as Map<String, dynamic>;
            newAccessToken = result['accessToken'] as String;
            final newRefreshToken = result['refreshToken'] as String;

            // 세션 갱신
            ref.read(authSessionProvider.notifier).setTokens(newAccessToken, newRefreshToken);

            // 자동로그인 체크 유저만 디스크에도 저장
            final autoLogin = await storage.getAutoLogin();
            if (autoLogin) {
              await storage.saveAccessToken(newAccessToken);
              await storage.saveRefreshToken(newRefreshToken);
            }
          } catch (_) {
            // refresh 실패 → 전체 초기화 후 로그인 화면
            ref.read(authSessionProvider.notifier).clearTokens();
            await ref.read(tokenStorageProvider).clearAll();
            router.go(AppRoutes.login);
          } finally {
            // finally로 completer를 반드시 한 번만 complete
            refreshCompleter!.complete(newAccessToken);
            refreshCompleter = null;
            isRefreshing = false;
          }

          if (newAccessToken != null) {
            try {
              handler.resolve(await _retry(dio, error.requestOptions, newAccessToken));
            } catch (_) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
          return;
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});

/// 원본 요청을 새 access token으로 재시도
Future<Response<dynamic>> _retry(
  Dio dio,
  RequestOptions requestOptions,
  String newAccessToken,
) {
  return dio.request<dynamic>(
    requestOptions.path,
    data: requestOptions.data,
    queryParameters: requestOptions.queryParameters,
    options: Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $newAccessToken',
      },
      contentType: requestOptions.contentType,
      responseType: requestOptions.responseType,
      extra: {...requestOptions.extra, '_retry': true},
    ),
  );
}
