import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';

/// 전화번호 관련 API provider
final phoneApiProvider = Provider<PhoneApi>((ref) {
  final dio = ref.read(dioProvider);
  return PhoneApi(dio);
});

class PhoneApi {
  final Dio _dio;

  PhoneApi(this._dio);

  /// 전화번호 중복 확인
  ///
  /// 요청:
  /// GET /api/auth/check-phone?phoneNumber=01012345678
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
  /// - true  : 이미 존재하는 전화번호
  /// - false : 사용 가능한 전화번호
  Future<bool> checkPhoneExists(String phoneNumber) async {
    final response = await _dio.get(
      '/api/auth/check-phone',
      queryParameters: {'phoneNumber': phoneNumber},
    );

    final data = response.data;

    /// 응답 최상위 타입 검사
    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않아요.');
    }

    /// API 성공 여부 확인
    if (data['isSuccess'] != true) {
      throw Exception('전화번호 확인에 실패했어요.');
    }

    final result = data['result'];

    /// result 타입 검사
    if (result is! Map<String, dynamic>) {
      throw Exception('result 형식이 올바르지 않아요.');
    }

    final exists = result['exists'];

    /// exists 타입 검사
    if (exists is! bool) {
      throw Exception('exists 값이 올바르지 않아요.');
    }

    return exists;
  }
}
