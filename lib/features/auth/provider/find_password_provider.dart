import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/email_api.dart';
import '../api/find_password_api.dart';
import 'find_password_state.dart';

final findPasswordProvider =
    StateNotifierProvider.autoDispose<FindPasswordNotifier, FindPasswordState>((
      ref,
    ) {
      final findPasswordApi = ref.read(findPasswordApiProvider);
      final emailApi = ref.read(emailApiProvider);
      return FindPasswordNotifier(findPasswordApi, emailApi);
    });

class FindPasswordNotifier extends StateNotifier<FindPasswordState> {
  final FindPasswordApi _findPasswordApi;
  final EmailApi _emailApi;

  FindPasswordNotifier(this._findPasswordApi, this._emailApi)
    : super(const FindPasswordState());

  Future<void> sendCode(String email) async {
    state = state.copyWith(
      isSendLoading: true,
      isSendSuccess: false,
      clearSendError: true,
      clearVerificationToken: true,
      clearVerifyError: true,
    );

    try {
      await _findPasswordApi.sendResetCode(email);
      state = state.copyWith(isSendLoading: false, isSendSuccess: true);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = '인증번호 발송에 실패했습니다.';

      if (data is Map<String, dynamic>) {
        final code = data['code'];
        if (code == 'USER4003')
          message = '가입되지 않은 이메일입니다.';
        else if (data['message'] is String)
          message = data['message'] as String;
      }

      state = state.copyWith(isSendLoading: false, sendError: message);
    } catch (_) {
      state = state.copyWith(
        isSendLoading: false,
        sendError: '인증번호 발송에 실패했습니다. 다시 시도해주세요.',
      );
    }
  }

  Future<void> verifyCode({required String email, required String code}) async {
    state = state.copyWith(
      isVerifyLoading: true,
      clearVerifyError: true,
      clearVerificationToken: true,
    );

    try {
      final token = await _emailApi.verifyCode(email: email, code: code);
      state = state.copyWith(isVerifyLoading: false, verificationToken: token);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = '인증번호가 올바르지 않습니다.';

      if (data is Map<String, dynamic> && data['message'] is String) {
        message = data['message'] as String;
      }

      state = state.copyWith(isVerifyLoading: false, verifyError: message);
    } catch (_) {
      state = state.copyWith(
        isVerifyLoading: false,
        verifyError: '인증 확인에 실패했습니다. 다시 시도해주세요.',
      );
    }
  }

  void resetVerify() {
    state = state.copyWith(
      clearVerificationToken: true,
      clearVerifyError: true,
    );
  }
}
