import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/verification_decision_request_model.dart';
import '../models/verification_request_detail_model.dart';
import '../models/verification_request_list_item_model.dart';
import '../models/verification_status_model.dart';

/// 관리자 학교 인증 API provider
final adminVerificationApiProvider = Provider<AdminVerificationApi>((ref) {
  final dio = ref.read(dioProvider);
  return AdminVerificationApi(dio);
});

class AdminVerificationApi {
  final Dio _dio;

  AdminVerificationApi(this._dio);

  Future<int> getPendingRequestCount() async {
    final requests = await getRequestList(VerificationStatusModel.pending);
    return requests.length;
  }

  /// 학교 인증 요청 목록 조회
  Future<List<VerificationRequestListItemModel>> getRequestList(
    VerificationStatusModel status,
  ) async {
    final response = await _dio.get(
      '/api/admin/verification-requests',
      queryParameters: {'status': status.toQueryValue},
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('목록 조회에 실패했습니다.');
    }

    final result = data['result'];

    if (result is! List) {
      throw Exception('목록 데이터 형식이 올바르지 않습니다.');
    }

    return result
        .map(
          (e) => VerificationRequestListItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// 학교 인증 요청 상세 조회
  Future<VerificationRequestDetailModel> getRequestDetail(int requestId) async {
    final response = await _dio.get(
      '/api/admin/verification-requests/$requestId',
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('상세 조회에 실패했습니다.');
    }

    final result = data['result'];

    if (result is! Map<String, dynamic>) {
      throw Exception('상세 데이터 형식이 올바르지 않습니다.');
    }

    return VerificationRequestDetailModel.fromJson(result);
  }

  /// 학교 인증 요청 승인
  Future<void> approveRequest({
    required int requestId,
    required VerificationDecisionRequestModel request,
  }) async {
    final response = await _dio.patch(
      '/api/admin/verification-requests/$requestId/approve',
      data: request.toJson(),
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('승인 처리에 실패했습니다.');
    }
  }

  /// 학교 인증 요청 거절
  Future<void> rejectRequest({
    required int requestId,
    required VerificationDecisionRequestModel request,
  }) async {
    final response = await _dio.patch(
      '/api/admin/verification-requests/$requestId/reject',
      data: request.toJson(),
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }

    if (data['isSuccess'] != true) {
      throw Exception('거절 처리에 실패했습니다.');
    }
  }
}
