/// 이메일 인증번호 확인 상태
class SignupEmailVerifyState {
  /// 인증번호 확인 중 여부
  final bool isLoading;

  /// 인증 성공 여부
  final bool isSuccess;

  /// 인증 성공 시 받은 토큰
  final String verificationToken;

  /// 에러 메시지
  final String? errorMessage;

  const SignupEmailVerifyState({
    this.isLoading = false,
    this.isSuccess = false,
    this.verificationToken = '',
    this.errorMessage,
  });

  SignupEmailVerifyState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? verificationToken,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SignupEmailVerifyState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      verificationToken: verificationToken ?? this.verificationToken,
      errorMessage:
      clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}