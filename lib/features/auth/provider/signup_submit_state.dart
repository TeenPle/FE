/// 회원가입 요청 상태
class SignupSubmitState {
  /// 요청 중 여부
  final bool isLoading;

  /// 회원가입 성공 여부
  final bool isSuccess;

  /// 에러 메시지
  final String? errorMessage;

  const SignupSubmitState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  SignupSubmitState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SignupSubmitState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage:
      clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}