import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/find_email_api.dart';
import 'find_email_state.dart';

final findEmailProvider =
    StateNotifierProvider.autoDispose<FindEmailNotifier, FindEmailState>((ref) {
  final api = ref.read(findEmailApiProvider);
  return FindEmailNotifier(api);
});

class FindEmailNotifier extends StateNotifier<FindEmailState> {
  final FindEmailApi _api;

  FindEmailNotifier(this._api) : super(const FindEmailState());

  Future<void> findEmail({
    required String username,
    required String phoneNumber,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearMaskedEmail: true,
    );

    try {
      final maskedEmail = await _api.findEmail(
        username: username,
        phoneNumber: phoneNumber,
      );

      state = state.copyWith(isLoading: false, maskedEmail: maskedEmail);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = '일치하는 계정을 찾을 수 없습니다.';

      if (data is Map<String, dynamic> && data['message'] is String) {
        message = data['message'] as String;
      }

      state = state.copyWith(isLoading: false, errorMessage: message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '이메일 찾기에 실패했습니다. 다시 시도해주세요.',
      );
    }
  }

  void reset() {
    state = const FindEmailState();
  }
}
