import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/nickname_api.dart';
import 'signup_nickname_check_state.dart';

/// 닉네임 중복 확인 상태를 관리하는 provider
final signupNicknameCheckProvider =
    StateNotifierProvider<
      SignupNicknameCheckNotifier,
      SignupNicknameCheckState
    >((ref) {
      final nicknameApi = ref.read(nicknameApiProvider);
      return SignupNicknameCheckNotifier(nicknameApi);
    });

class SignupNicknameCheckNotifier
    extends StateNotifier<SignupNicknameCheckState> {
  final NicknameApi _nicknameApi;

  SignupNicknameCheckNotifier(this._nicknameApi)
    : super(const SignupNicknameCheckState());

  /// 닉네임 중복 확인
  Future<void> checkNickname(String nickname) async {
    final trimmed = nickname.trim();

    /// 빈 문자열이면 상태 초기화
    if (trimmed.isEmpty) {
      reset();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      checkedNickname: trimmed,
      clearAvailability: true,
      clearErrorMessage: true,
    );

    try {
      /// true  -> 이미 존재
      /// false -> 사용 가능
      final exists = await _nicknameApi.checkNicknameExists(trimmed);

      state = state.copyWith(
        isLoading: false,
        checkedNickname: trimmed,
        isAvailable: !exists,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        checkedNickname: trimmed,
        errorMessage: _mapDioErrorToMessage(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        checkedNickname: trimmed,
        errorMessage: '닉네임 확인에 실패했어요.',
      );
    }
  }

  /// 상태 초기화
  void reset() {
    state = const SignupNicknameCheckState();
  }

  /// 사용자에게 보여줄 짧은 에러 메시지로 변환
  String _mapDioErrorToMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (statusCode == 400) {
      return '닉네임 형식이 올바르지 않아요.';
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '네트워크 상태를 확인한 뒤 다시 시도해 주세요.';
    }

    return '닉네임 확인에 실패했어요.';
  }
}
