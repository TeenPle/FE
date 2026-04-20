/// 닉네임 중복 확인 상태
class SignupNicknameCheckState {
  /// 중복 확인 API 호출 중인지 여부
  final bool isLoading;

  /// 사용 가능 여부
  /// - true  : 사용 가능
  /// - false : 이미 사용 중
  /// - null  : 아직 확인 안 함
  final bool? isAvailable;

  /// 마지막으로 확인한 닉네임
  final String checkedNickname;

  /// 에러 메시지
  final String? errorMessage;

  const SignupNicknameCheckState({
    this.isLoading = false,
    this.isAvailable,
    this.checkedNickname = '',
    this.errorMessage,
  });

  SignupNicknameCheckState copyWith({
    bool? isLoading,
    bool? isAvailable,
    String? checkedNickname,
    String? errorMessage,
    bool clearAvailability = false,
    bool clearErrorMessage = false,
  }) {
    return SignupNicknameCheckState(
      isLoading: isLoading ?? this.isLoading,
      isAvailable: clearAvailability ? null : (isAvailable ?? this.isAvailable),
      checkedNickname: checkedNickname ?? this.checkedNickname,
      errorMessage:
      clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}