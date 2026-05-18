import '../models/login_blocked_reason.dart';
import '../models/login_response_model.dart';

/// 로그인 화면 상태
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final LoginResponseModel? loginResponse;
  final LoginBlockedReason? blockedReason;

  /// 마지막 로그인 시도에 사용한 이메일
  final String attemptedEmail;

  /// 마지막 로그인 시도에 사용한 비밀번호
  /// 메모리에만 잠깐 유지
  final String attemptedPassword;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.loginResponse,
    this.blockedReason,
    this.attemptedEmail = '',
    this.attemptedPassword = '',
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    LoginResponseModel? loginResponse,
    LoginBlockedReason? blockedReason,
    String? attemptedEmail,
    String? attemptedPassword,
    bool clearErrorMessage = false,
    bool clearLoginResponse = false,
    bool clearBlockedReason = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      loginResponse: clearLoginResponse
          ? null
          : (loginResponse ?? this.loginResponse),
      blockedReason: clearBlockedReason
          ? null
          : (blockedReason ?? this.blockedReason),
      attemptedEmail: attemptedEmail ?? this.attemptedEmail,
      attemptedPassword: attemptedPassword ?? this.attemptedPassword,
    );
  }
}
