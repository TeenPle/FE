/// 전화번호 중복 확인 상태
class SignupPhoneCheckState {
  /// 중복 확인 API 호출 중인지 여부
  final bool isLoading;

  /// 사용 가능 여부
  /// - true  : 사용 가능
  /// - false : 이미 사용 중
  /// - null  : 아직 확인 안 함
  final bool? isAvailable;

  /// 마지막으로 확인한 전화번호
  final String checkedPhoneNumber;

  /// 에러 메시지
  final String? errorMessage;

  const SignupPhoneCheckState({
    this.isLoading = false,
    this.isAvailable,
    this.checkedPhoneNumber = '',
    this.errorMessage,
  });

  SignupPhoneCheckState copyWith({
    bool? isLoading,
    bool? isAvailable,
    String? checkedPhoneNumber,
    String? errorMessage,
    bool clearAvailability = false,
    bool clearErrorMessage = false,
  }) {
    return SignupPhoneCheckState(
      isLoading: isLoading ?? this.isLoading,
      isAvailable: clearAvailability ? null : (isAvailable ?? this.isAvailable),
      checkedPhoneNumber: checkedPhoneNumber ?? this.checkedPhoneNumber,
      errorMessage:
      clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}