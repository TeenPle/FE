import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';

/// 닉네임 관련 API provider
final nicknameApiProvider = Provider<NicknameApi>((ref) {
  final dio = ref.read(dioProvider);
  return NicknameApi(dio);
});

class NicknameApi {
  final Dio _dio;

  NicknameApi(this._dio);

  /// 닉네임 중복 확인
  ///
  /// 요청:
  /// GET /api/auth/check-nickname?nickname=카이사
  ///
  /// 응답:
  /// {
  ///   "isSuccess": true,
  ///   "result": {
  ///     "exists": true
  ///   }
  /// }
  ///
  /// 반환값:
  /// - true  : 이미 존재하는 닉네임
  /// - false : 사용 가능한 닉네임
  Future<bool> checkNicknameExists(String nickname) async {
    final response = await _dio.get(
      '/api/auth/check-nickname',
      queryParameters: {'nickname': nickname},
    );

    final data = response.data;

    /// 응답 최상위 타입 검사
    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }

    /// API 성공 여부 확인
    if (data['isSuccess'] != true) {
      throw Exception('닉네임 확인에 실패했습니다.');
    }

    final result = data['result'];

    /// result 타입 검사
    if (result is! Map<String, dynamic>) {
      throw Exception('result 형식이 올바르지 않습니다.');
    }

    final exists = result['exists'];

    /// exists 타입 검사
    if (exists is! bool) {
      throw Exception('exists 값이 올바르지 않습니다.');
    }

    return exists;
  }
}