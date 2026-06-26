import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';

final findPasswordApiProvider = Provider<FindPasswordApi>((ref) {
  final dio = ref.read(dioProvider);
  return FindPasswordApi(dio);
});

class FindPasswordApi {
  final Dio _dio;

  FindPasswordApi(this._dio);

  /// 비밀번호 재설정 인증번호 발송 (이메일 존재 여부 사전 확인)
  ///
  /// POST /api/auth/password/send-code
  Future<void> sendResetCode(String email) async {
    final response = await _dio.post(
      '/api/auth/password/send-code',
      data: {'email': email},
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않아요.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('인증번호 발송에 실패했어요.');
    }
  }

  /// 비밀번호 재설정
  ///
  /// POST /api/auth/reset-password
  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      '/api/auth/reset-password',
      data: {
        'verificationToken': verificationToken,
        'newPassword': newPassword,
      },
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않아요.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('비밀번호 재설정에 실패했어요.');
    }
  }
}
