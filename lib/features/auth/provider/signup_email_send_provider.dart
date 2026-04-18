import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/email_api.dart';
import 'signup_email_send_state.dart';

/// 이메일 인증번호 전송 상태 provider
final signupEmailSendProvider =
StateNotifierProvider<SignupEmailSendNotifier, SignupEmailSendState>((ref) {
  final emailApi = ref.read(emailApiProvider);
  return SignupEmailSendNotifier(emailApi);
});

class SignupEmailSendNotifier extends StateNotifier<SignupEmailSendState> {
  final EmailApi _emailApi;

  SignupEmailSendNotifier(this._emailApi)
      : super(const SignupEmailSendState());

  /// 인증번호 전송
  Future<void> sendCode(String email) async {
    final trimmed = email.trim();

    if (trimmed.isEmpty) {
      state = state.copyWith(
        errorMessage: '이메일이 비어 있습니다.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      clearErrorMessage: true,
    );

    try {
      await _emailApi.sendVerificationCode(trimmed);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.message ?? '인증번호 전송에 실패했습니다.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: '인증번호 전송에 실패했습니다.',
      );
    }
  }

  /// 상태 초기화
  void reset() {
    state = const SignupEmailSendState();
  }
}