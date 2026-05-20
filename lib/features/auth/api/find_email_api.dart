import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';

final findEmailApiProvider = Provider<FindEmailApi>((ref) {
  final dio = ref.read(dioProvider);
  return FindEmailApi(dio);
});

class FindEmailApi {
  final Dio _dio;

  FindEmailApi(this._dio);

  /// 이름 + 휴대폰 번호로 마스킹된 이메일 반환
  ///
  /// POST /api/auth/find-email
  Future<String> findEmail({
    required String username,
    required String phoneNumber,
  }) async {
    final response = await _dio.post(
      '/api/auth/find-email',
      data: {'username': username, 'phoneNumber': phoneNumber},
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않아요.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('이메일 찾기에 실패했어요.');
    }

    final result = data['result'];

    if (result is! Map<String, dynamic>) {
      throw Exception('result 형식이 올바르지 않아요.');
    }

    final maskedEmail = result['maskedEmail'];

    if (maskedEmail is! String) {
      throw Exception('maskedEmail 형식이 올바르지 않아요.');
    }

    return maskedEmail;
  }
}
