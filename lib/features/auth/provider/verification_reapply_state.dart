import '../models/verification_reapply_info_response_model.dart';

/// 반려 사유 조회 / 재요청 상태
class VerificationReapplyState {
  final bool isInfoLoading;
  final bool isSubmitLoading;
  final VerificationReapplyInfoResponseModel? info;
  final String selectedFilePath;
  final String? errorMessage;
  final String? submitErrorMessage;
  final bool isSubmitSuccess;

  const VerificationReapplyState({
    this.isInfoLoading = false,
    this.isSubmitLoading = false,
    this.info,
    this.selectedFilePath = '',
    this.errorMessage,
    this.submitErrorMessage,
    this.isSubmitSuccess = false,
  });

  VerificationReapplyState copyWith({
    bool? isInfoLoading,
    bool? isSubmitLoading,
    VerificationReapplyInfoResponseModel? info,
    String? selectedFilePath,
    String? errorMessage,
    String? submitErrorMessage,
    bool? isSubmitSuccess,
    bool clearErrorMessage = false,
    bool clearSubmitErrorMessage = false,
  }) {
    return VerificationReapplyState(
      isInfoLoading: isInfoLoading ?? this.isInfoLoading,
      isSubmitLoading: isSubmitLoading ?? this.isSubmitLoading,
      info: info ?? this.info,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      submitErrorMessage: clearSubmitErrorMessage
          ? null
          : (submitErrorMessage ?? this.submitErrorMessage),
      isSubmitSuccess: isSubmitSuccess ?? this.isSubmitSuccess,
    );
  }
}
