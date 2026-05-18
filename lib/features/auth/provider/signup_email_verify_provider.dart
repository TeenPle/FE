import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/email_api.dart';
import 'signup_email_verify_state.dart';

/// 이메일 인증번호 확인 상태 provider
final signupEmailVerifyProvider =
    StateNotifierProvider<SignupEmailVerifyNotifier, SignupEmailVerifyState>((
      ref,
    ) {
      final emailApi = ref.read(emailApiProvider);
      return SignupEmailVerifyNotifier(emailApi);
    });

class SignupEmailVerifyNotifier extends StateNotifier<SignupEmailVerifyState> {
  final EmailApi _emailApi;

  SignupEmailVerifyNotifier(this._emailApi)
    : super(const SignupEmailVerifyState());

  /// 인증번호 검증
  Future<void> verify({required String email, required String code}) async {
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      verificationToken: '',
      clearErrorMessage: true,
    );

    try {
      final verificationToken = await _emailApi.verifyCode(
        email: email,
        code: code,
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        verificationToken: verificationToken,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: _mapDioErrorToMessage(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: '인증번호 확인에 실패했습니다. 다시 시도해주세요.',
      );
    }
  }

  /// 상태 초기화
  void reset() {
    state = const SignupEmailVerifyState();
  }

  /// Dio 예외를 사용자에게 보여줄 짧은 메시지로 변환
  String _mapDioErrorToMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    /// 백엔드에서 message 필드를 내려주는 경우 우선 사용
    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    /// 인증번호 불일치/만료 등은 보통 400으로 처리
    if (statusCode == 400) {
      return '인증번호가 올바르지 않거나 만료되었습니다.';
    }

    /// 네트워크 오류
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '네트워크 상태를 확인한 뒤 다시 시도해주세요.';
    }

    return '인증번호 확인에 실패했습니다. 다시 시도해주세요.';
  }
}
