import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_verification_api.dart';
import '../models/verification_decision_request_model.dart';
import 'admin_verification_detail_state.dart';

/// 관리자 인증 요청 상세 provider
/// autoDispose: 페이지를 떠나면 상태 초기화 → 재진입 시 항상 최신 상태로 조회
final adminVerificationDetailProvider = StateNotifierProvider.autoDispose.family<
    AdminVerificationDetailNotifier, AdminVerificationDetailState, int>(
      (ref, requestId) {
    final api = ref.read(adminVerificationApiProvider);
    return AdminVerificationDetailNotifier(api, requestId);
  },
);

class AdminVerificationDetailNotifier
    extends StateNotifier<AdminVerificationDetailState> {
  final AdminVerificationApi _api;
  final int requestId;

  AdminVerificationDetailNotifier(this._api, this.requestId)
      : super(const AdminVerificationDetailState()) {
    fetchDetail();
  }

  /// 상세 조회
  Future<void> fetchDetail() async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearActionErrorMessage: true,
      isActionSuccess: false,
    );

    try {
      final result = await _api.getRequestDetail(requestId);

      state = state.copyWith(
        isLoading: false,
        detail: result,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapDioErrorToMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// 승인/거절 에러 상태 초기화
  void clearActionState() {
    state = state.copyWith(
      clearActionErrorMessage: true,
      isActionSuccess: false,
    );
  }

  /// 승인 처리
  Future<void> approve(String adminComment) async {
    final trimmed = adminComment.trim();

    /// 승인도 코멘트가 필수인 경우 프론트에서 먼저 막음
    if (trimmed.isEmpty) {
      state = state.copyWith(
        actionErrorMessage: '승인 코멘트를 입력해주세요.',
      );
      return;
    }

    state = state.copyWith(
      isActionLoading: true,
      clearActionErrorMessage: true,
      isActionSuccess: false,
    );

    try {
      await _api.approveRequest(
        requestId: requestId,
        request: VerificationDecisionRequestModel(
          adminComment: trimmed,
        ),
      );

      state = state.copyWith(
        isActionLoading: false,
        isActionSuccess: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionErrorMessage: _mapDioErrorToMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// 거절 처리
  Future<void> reject(String adminComment) async {
    final trimmed = adminComment.trim();

    if (trimmed.isEmpty) {
      state = state.copyWith(
        actionErrorMessage: '거절 사유를 입력해주세요.',
      );
      return;
    }

    state = state.copyWith(
      isActionLoading: true,
      clearActionErrorMessage: true,
      isActionSuccess: false,
    );

    try {
      await _api.rejectRequest(
        requestId: requestId,
        request: VerificationDecisionRequestModel(
          adminComment: trimmed,
        ),
      );

      state = state.copyWith(
        isActionLoading: false,
        isActionSuccess: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionErrorMessage: _mapDioErrorToMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// 백엔드 message 추출
  String? _extractBackendMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final directMessage = data['message'];
    if (directMessage is String && directMessage.trim().isNotEmpty) {
      return directMessage.trim();
    }

    final result = data['result'];
    if (result is Map<String, dynamic>) {
      final nestedMessage = result['message'];
      if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
        return nestedMessage.trim();
      }
    }

    return null;
  }

  /// Dio 에러를 사용자용 메시지로 변환
  String _mapDioErrorToMessage(DioException e) {
    final message = _extractBackendMessage(e.response?.data);
    final statusCode = e.response?.statusCode;

    if (message != null && message.isNotEmpty) {
      return message;
    }

    if (statusCode == 400) {
      return '입력값을 다시 확인해주세요.';
    }

    if (statusCode == 403) {
      return '관리자 권한이 없습니다.';
    }

    if (statusCode == 404) {
      return '인증 요청을 찾을 수 없습니다.';
    }

    if (statusCode == 500) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '네트워크 상태를 확인한 뒤 다시 시도해주세요.';
    }

    return '처리에 실패했습니다. 다시 시도해주세요.';
  }
}