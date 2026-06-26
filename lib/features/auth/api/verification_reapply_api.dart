import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/dio_provider.dart';
import '../models/verification_reapply_info_request_model.dart';
import '../models/verification_reapply_info_response_model.dart';
import '../models/verification_reapply_request_model.dart';

/// 반려 사유 조회 / 재요청 API provider
final verificationReapplyApiProvider = Provider<VerificationReapplyApi>((ref) {
  final dio = ref.read(dioProvider);
  return VerificationReapplyApi(dio);
});

class VerificationReapplyApi {
  final Dio _dio;

  VerificationReapplyApi(this._dio);

  /// 반려 사유 조회
  Future<VerificationReapplyInfoResponseModel> getReapplyInfo(
    VerificationReapplyInfoRequestModel request,
  ) async {
    final response = await _dio.post(
      '/api/auth/verification/reapply-info',
      data: request.toJson(),
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않아요.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('반려 사유 조회에 실패했어요.');
    }

    final result = data['result'];

    if (result is! Map<String, dynamic>) {
      throw Exception('반려 사유 데이터 형식이 올바르지 않아요.');
    }

    return VerificationReapplyInfoResponseModel.fromJson(result);
  }

  /// 학생증 재업로드 후 재요청
  Future<int> reapply({
    required VerificationReapplyRequestModel request,
    required String studentCardFilePath,
  }) async {
    final fileName = studentCardFilePath.split(RegExp(r'[\\/]')).last;

    final formData = FormData.fromMap({
      'data': MultipartFile.fromString(
        jsonEncode(request.toJson()),
        contentType: MediaType('application', 'json'),
      ),
      'studentCard': await MultipartFile.fromFile(
        studentCardFilePath,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/api/auth/verification/reapply',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않아요.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('재요청에 실패했어요.');
    }

    final result = data['result'];
    if (result is! num) {
      throw Exception('재요청 결과 형식이 올바르지 않아요.');
    }

    return result.toInt();
  }
}
