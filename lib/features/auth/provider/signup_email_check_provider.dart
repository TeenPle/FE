import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/email_api.dart';
import 'signup_email_check_state.dart';

/// 이메일 중복 확인 상태를 관리하는 provider
final signupEmailCheckProvider =
    StateNotifierProvider<SignupEmailCheckNotifier, SignupEmailCheckState>((
      ref,
    ) {
      final emailApi = ref.read(emailApiProvider);
      return SignupEmailCheckNotifier(emailApi);
    });

class SignupEmailCheckNotifier extends StateNotifier<SignupEmailCheckState> {
  final EmailApi _emailApi;

  SignupEmailCheckNotifier(this._emailApi)
    : super(const SignupEmailCheckState());

  /// 이메일 중복 확인
  Future<void> checkEmail(String email) async {
    final trimmed = email.trim();

    /// 빈 문자열이면 상태 초기화
    if (trimmed.isEmpty) {
      reset();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      checkedEmail: trimmed,
      clearAvailability: true,
      clearErrorMessage: true,
    );

    try {
      /// true  -> 이미 존재
      /// false -> 사용 가능
      final exists = await _emailApi.checkEmailExists(trimmed);

      state = state.copyWith(
        isLoading: false,
        checkedEmail: trimmed,
        isAvailable: !exists,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        checkedEmail: trimmed,
        errorMessage: e.message ?? '이메일 확인에 실패했습니다.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        checkedEmail: trimmed,
        errorMessage: '이메일 확인에 실패했습니다.',
      );
    }
  }

  /// 중복 확인 상태 초기화
  void reset() {
    state = const SignupEmailCheckState();
  }
}
