/// 이메일 인증번호 전송 상태
class SignupEmailSendState {
  /// 전송 중 여부
  final bool isLoading;

  /// 전송 완료 여부
  final bool isSuccess;

  /// 에러 메시지
  final String? errorMessage;

  const SignupEmailSendState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  SignupEmailSendState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SignupEmailSendState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
