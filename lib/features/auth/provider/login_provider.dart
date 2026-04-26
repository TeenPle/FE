import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../../notification/service/fcm_service.dart';
import '../api/login_api.dart';
import '../models/login_blocked_reason.dart';
import '../models/login_request_model.dart';
import 'login_state.dart';

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  final loginApi = ref.read(loginApiProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  final authSession = ref.read(authSessionProvider.notifier);
  final fcmService = ref.read(fcmServiceProvider);
  return LoginNotifier(loginApi, tokenStorage, authSession, fcmService);
});

class LoginNotifier extends StateNotifier<LoginState> {
  final LoginApi _loginApi;
  final TokenStorage _tokenStorage;
  final AuthSessionNotifier _authSession;
  final FcmService _fcmService;

  LoginNotifier(this._loginApi, this._tokenStorage, this._authSession, this._fcmService)
      : super(const LoginState());

  /// [keepLoggedIn]이 true인 경우에만 토큰을 디스크에 저장.
  Future<void> login({
    required String email,
    required String password,
    required bool keepLoggedIn,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty) {
      state = state.copyWith(
        errorMessage: '이메일을 입력해주세요.',
        clearLoginResponse: true,
        clearBlockedReason: true,
      );
      return;
    }

    if (trimmedPassword.isEmpty) {
      state = state.copyWith(
        errorMessage: '비밀번호를 입력해주세요.',
        clearLoginResponse: true,
        clearBlockedReason: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      attemptedEmail: trimmedEmail,
      attemptedPassword: trimmedPassword,
      clearErrorMessage: true,
      clearLoginResponse: true,
      clearBlockedReason: true,
    );

    try {
      final result = await _loginApi.login(
        LoginRequestModel(email: trimmedEmail, password: trimmedPassword),
      );

      // 항상 메모리 세션에 저장
      _authSession.setTokens(result.accessToken, result.refreshToken);

      if (keepLoggedIn) {
        // 자동로그인 체크: 디스크에도 저장
        await _tokenStorage.saveAccessToken(result.accessToken);
        await _tokenStorage.saveRefreshToken(result.refreshToken);
        await _tokenStorage.saveAutoLogin(true);
        await _tokenStorage.saveUserRole(result.role);
      } else {
        // 자동로그인 미체크: 이전 토큰/역할 클리어
        await _tokenStorage.clearAll();
      }

      // 학교 ID는 자동로그인 여부와 무관하게 항상 저장 (급식/시간표 기능에 필요)
      if (result.schoolId != null) {
        await _tokenStorage.saveSchoolId(result.schoolId!);
      }

      state = state.copyWith(isLoading: false, loginResponse: result);
    } on DioException catch (e) {
      final backendCode = _extractBackendCode(e.response?.data);
      final blockedReason = _mapBlockedReason(backendCode);

      if (blockedReason != null) {
        state = state.copyWith(isLoading: false, blockedReason: blockedReason);
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapDioErrorToMessage(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '로그인에 실패했습니다. 다시 시도해주세요.',
      );
    }
  }

  void clearTransientState() {
    state = state.copyWith(
      clearErrorMessage: true,
      clearLoginResponse: true,
      clearBlockedReason: true,
    );
  }

  Future<void> logout() async {
    final refreshToken = _authSession.state.refreshToken
        ?? await _tokenStorage.getRefreshToken();

    // FCM 토큰 서버 삭제 및 로컬 삭제
    try {
      await _fcmService.deleteToken();
    } catch (_) {}

    // 서버에 refresh token 무효화 (실패해도 로컬은 반드시 초기화)
    if (refreshToken != null) {
      try {
        await _loginApi.logout(refreshToken);
      } catch (_) {}
    }

    _authSession.clearTokens();
    await _tokenStorage.clearAll();
    state = const LoginState();
  }

  void reset() {
    state = const LoginState();
  }

  String? _extractBackendCode(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final directCode = data['code'];
    if (directCode is String && directCode.trim().isNotEmpty) return directCode.trim();
    final result = data['result'];
    if (result is Map<String, dynamic>) {
      final nestedCode = result['code'];
      if (nestedCode is String && nestedCode.trim().isNotEmpty) return nestedCode.trim();
    }
    return null;
  }

  String? _extractBackendMessage(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final directMessage = data['message'];
    if (directMessage is String && directMessage.trim().isNotEmpty) return directMessage.trim();
    final result = data['result'];
    if (result is Map<String, dynamic>) {
      final nestedMessage = result['message'];
      if (nestedMessage is String && nestedMessage.trim().isNotEmpty) return nestedMessage.trim();
    }
    return null;
  }

  LoginBlockedReason? _mapBlockedReason(String? code) {
    switch (code) {
      case 'USER4031': return LoginBlockedReason.required;
      case 'USER4032': return LoginBlockedReason.pending;
      case 'USER4033': return LoginBlockedReason.rejected;
      case 'USER5001': return LoginBlockedReason.invalid;
      default: return null;
    }
  }

  String _mapDioErrorToMessage(DioException e) {
    final code = _extractBackendCode(e.response?.data);
    final message = _extractBackendMessage(e.response?.data);
    final statusCode = e.response?.statusCode;

    switch (code) {
      case 'USER4003': return '존재하지 않는 이메일입니다.';
      case 'USER4004': return '비밀번호가 일치하지 않습니다.';
    }

    if (message != null && message.isNotEmpty) return message;
    if (statusCode == 401) return '이메일 또는 비밀번호를 다시 확인해주세요.';
    if (statusCode == 403) return '로그인이 제한된 계정입니다.';
    if (statusCode == 500) return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '네트워크 상태를 확인한 뒤 다시 시도해주세요.';
    }

    return '로그인에 실패했습니다. 다시 시도해주세요.';
  }
}
