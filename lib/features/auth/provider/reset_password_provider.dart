import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/find_password_api.dart';
import 'reset_password_state.dart';

final resetPasswordProvider =
    StateNotifierProvider.autoDispose<
      ResetPasswordNotifier,
      ResetPasswordState
    >((ref) {
      final api = ref.read(findPasswordApiProvider);
      return ResetPasswordNotifier(api);
    });

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  final FindPasswordApi _api;

  ResetPasswordNotifier(this._api) : super(const ResetPasswordState());

  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      clearErrorMessage: true,
    );

    try {
      await _api.resetPassword(
        verificationToken: verificationToken,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = '비밀번호 재설정에 실패했어요.';

      if (data is Map<String, dynamic>) {
        final code = data['code'];
        if (code == 'USER4007') {
          message = '현재 비밀번호와 같아요. 다른 비밀번호를 입력해 주세요.';
        } else if (data['message'] is String) {
          message = data['message'] as String;
        }
      }

      state = state.copyWith(isLoading: false, errorMessage: message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '비밀번호 재설정에 실패했어요. 다시 시도해 주세요.',
      );
    }
  }
}
