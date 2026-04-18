import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';

/// 이메일 관련 API provider
final emailApiProvider = Provider<EmailApi>((ref) {
  final dio = ref.read(dioProvider);
  return EmailApi(dio);
});

class EmailApi {
  final Dio _dio;

  EmailApi(this._dio);

  /// 이메일 중복 확인
  Future<bool> checkEmailExists(String email) async {
    final response = await _dio.get(
      '/api/auth/check-email',
      queryParameters: {'email': email},
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('이메일 중복 확인에 실패했습니다.');
    }

    final result = data['result'];

    if (result is! Map<String, dynamic>) {
      throw Exception('result 형식이 올바르지 않습니다.');
    }

    final exists = result['exists'];

    if (exists is! bool) {
      throw Exception('exists 값이 올바르지 않습니다.');
    }

    return exists;
  }

  /// 이메일 인증번호 전송
  Future<void> sendVerificationCode(String email) async {
    final response = await _dio.post(
      '/api/auth/email/send',
      data: {'email': email},
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('인증번호 전송에 실패했습니다.');
    }
  }

  /// 이메일 인증번호 검증
  ///
  /// 성공 시 verificationToken 반환
  Future<String> verifyCode({
    required String email,
    required String code,
  }) async {
    final response = await _dio.post(
      '/api/auth/email/verify',
      data: {
        'email': email,
        'code': code,
      },
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('인증번호 확인에 실패했습니다.');
    }

    final result = data['result'];

    if (result is! Map<String, dynamic>) {
      throw Exception('result 형식이 올바르지 않습니다.');
    }

    final verificationToken = result['verificationToken'];

    if (verificationToken is! String) {
      throw Exception('verificationToken 형식이 올바르지 않습니다.');
    }

    return verificationToken;
  }
}