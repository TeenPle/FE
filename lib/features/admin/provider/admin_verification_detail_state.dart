import '../models/verification_request_detail_model.dart';

/// 관리자 인증 요청 상세 상태
class AdminVerificationDetailState {
  final bool isLoading;
  final bool isActionLoading;
  final VerificationRequestDetailModel? detail;
  final String? errorMessage;
  final String? actionErrorMessage;
  final bool isActionSuccess;

  const AdminVerificationDetailState({
    this.isLoading = true,
    this.isActionLoading = false,
    this.detail,
    this.errorMessage,
    this.actionErrorMessage,
    this.isActionSuccess = false,
  });

  AdminVerificationDetailState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    VerificationRequestDetailModel? detail,
    String? errorMessage,
    String? actionErrorMessage,
    bool? isActionSuccess,
    bool clearErrorMessage = false,
    bool clearActionErrorMessage = false,
  }) {
    return AdminVerificationDetailState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      detail: detail ?? this.detail,
      errorMessage:
      clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      isActionSuccess: isActionSuccess ?? this.isActionSuccess,
    );
  }
}