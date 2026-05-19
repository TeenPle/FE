import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';

/// 로그인 API provider
final loginApiProvider = Provider<LoginApi>((ref) {
  final dio = ref.read(dioProvider);
  return LoginApi(dio);
});

class LoginApi {
  final Dio _dio;

  LoginApi(this._dio);

  /// 로그인 요청
  ///
  /// POST /api/auth/login
  /// body:
  /// {
  ///   "email": "...",
  ///   "password": "..."
  /// }
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await _dio.post('/api/auth/login', data: request.toJson());

    final data = response.data;

    /// 응답 최상위 형식 검사
    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }

    /// 성공 여부 검사
    if (data['isSuccess'] != true) {
      throw Exception('로그인에 실패했습니다.');
    }

    final result = data['result'];

    /// result 형식 검사
    if (result is! Map<String, dynamic>) {
      throw Exception('로그인 결과 형식이 올바르지 않습니다.');
    }

    return LoginResponseModel.fromJson(result);
  }

  /// 탈퇴 유예 계정 복구 — 이메일·비밀번호로 본인 확인 후 ACTIVE 복구, 새 토큰 발급
  ///
  /// POST /api/auth/restore
  Future<LoginResponseModel> restoreAccount({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/restore',
      data: {'email': email, 'password': password},
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }
    if (data['isSuccess'] != true) {
      throw Exception(data['message'] ?? '복구에 실패했습니다.');
    }

    final result = data['result'];
    if (result is! Map<String, dynamic>) {
      throw Exception('복구 결과 형식이 올바르지 않습니다.');
    }

    return LoginResponseModel.fromJson(result);
  }

  /// 로그아웃 - 서버에서 refresh token 무효화
  ///
  /// POST /api/auth/logout
  Future<void> logout(String refreshToken) async {
    await _dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
  }
}
