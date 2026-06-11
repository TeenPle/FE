import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notification/service/fcm_service.dart';
import '../api/signup_api.dart';
import 'signup_form_state.dart';
import 'signup_submit_state.dart';

/// 회원가입 요청 상태 provider
final signupSubmitProvider =
    StateNotifierProvider<SignupSubmitNotifier, SignupSubmitState>((ref) {
      final signupApi = ref.read(signupApiProvider);
      final fcmService = ref.read(fcmServiceProvider);
      return SignupSubmitNotifier(signupApi, fcmService);
    });

class SignupSubmitNotifier extends StateNotifier<SignupSubmitState> {
  final SignupApi _signupApi;
  final FcmService _fcmService;

  SignupSubmitNotifier(this._signupApi, this._fcmService)
    : super(const SignupSubmitState());

  /// 회원가입 요청
  Future<void> submit(
    SignupFormState formState, {
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      clearErrorMessage: true,
    );

    try {
      // 인증 승인 전에는 로그인이 막혀 푸시 토큰을 등록할 수 없으므로
      // 가입 요청에 토큰을 함께 실어 보낸다. (승인/거절 결과 푸시 수신용)
      // 권한 거부·발급 실패 시 null — 가입은 그대로 진행한다.
      final fcm = await _fcmService.obtainTokenForSignup();

      await _signupApi.signUp(
        formState,
        password: password,
        fcmToken: fcm?.token,
        fcmPlatform: fcm?.platform,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: _mapDioErrorToMessage(e),
      );
    } catch (e) {
      /// 프론트 사전검사에서 발생한 Exception 메시지를 그대로 보여줌
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// 상태 초기화
  void reset() {
    state = const SignupSubmitState();
  }

  /// Dio 예외를 사용자용 메시지로 변환
  String _mapDioErrorToMessage(DioException e) {
    final data = e.response?.data;
    final statusCode = e.response?.statusCode;

    if (data is Map<String, dynamic>) {
      /// 백엔드가 message 내려주면 우선 사용
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (statusCode == 400) {
      return '서버에서 요청을 거부했어요. 입력값 형식을 다시 확인해 주세요.';
    }

    if (statusCode == 401) {
      return '인증 정보가 올바르지 않아요.';
    }

    if (statusCode == 500) {
      return '서버 오류가 발생했어요. 잠시 후 다시 시도해 주세요.';
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '네트워크 상태를 확인한 뒤 다시 시도해 주세요.';
    }

    return '회원가입에 실패했어요.';
  }
}
