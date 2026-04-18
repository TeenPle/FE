/// 이메일 중복 확인 상태
class SignupEmailCheckState {
  /// 중복 확인 API 호출 중인지 여부
  final bool isLoading;

  /// 사용 가능 여부
  /// - true  : 사용 가능
  /// - false : 이미 사용 중
  /// - null  : 아직 확인 안 함
  final bool? isAvailable;

  /// 마지막으로 확인한 /// 이메일 중복 확인 상태
  // class SignupEmailCheckState {
  //   /// 중복 확인 API 호출 중인지 여부
  //   final bool isLoading;
  //
  //   /// 사용 가능 여부
  //   /// - true  : 사용 가능
  //   /// - false : 이미 사용 중
  //   /// - null  : 아직 확인 안 함
  //   final bool? isAvailable;
  //
  //   /// 마지막으로 확인한 이메일
  //   final String checkedEmail;
  //
  //   /// 에러 메시지
  //   final String? errorMessage;
  //
  //   const SignupEmailCheckState({
  //     this.isLoading = false,
  //     this.isAvailable,
  //     this.checkedEmail = '',
  //     this.errorMessage,
  //   });
  //
  //   SignupEmailCheckState copyWith({
  //     bool? isLoading,
  //     bool? isAvailable,
  //     String? checkedEmail,
  //     String? errorMessage,
  //     bool clearAvailability = false,
  //     bool clearErrorMessage = false,
  //   }) {
  //     return SignupEmailCheckState(
  //       isLoading: isLoading ?? this.isLoading,
  //       isAvailable: clearAvailability ? null : (isAvailable ?? this.isAvailable),
  //       checkedEmail: checkedEmail ?? this.checkedEmail,
  //       errorMessage:
  //           clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
  //     );
  //   }
  // }
  final String checkedEmail;

  /// 에러 메시지
  final String? errorMessage;

  const SignupEmailCheckState({
    this.isLoading = false,
    this.isAvailable,
    this.checkedEmail = '',
    this.errorMessage,
  });

  SignupEmailCheckState copyWith({
    bool? isLoading,
    bool? isAvailable,
    String? checkedEmail,
    String? errorMessage,
    bool clearAvailability = false,
    bool clearErrorMessage = false,
  }) {
    return SignupEmailCheckState(
      isLoading: isLoading ?? this.isLoading,
      isAvailable: clearAvailability ? null : (isAvailable ?? this.isAvailable),
      checkedEmail: checkedEmail ?? this.checkedEmail,
      errorMessage:
      clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}