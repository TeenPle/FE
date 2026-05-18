import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/phone_api.dart';
import 'signup_phone_check_state.dart';

/// 전화번호 중복 확인 상태를 관리하는 provider
final signupPhoneCheckProvider =
    StateNotifierProvider<SignupPhoneCheckNotifier, SignupPhoneCheckState>((
      ref,
    ) {
      final phoneApi = ref.read(phoneApiProvider);
      return SignupPhoneCheckNotifier(phoneApi);
    });

class SignupPhoneCheckNotifier extends StateNotifier<SignupPhoneCheckState> {
  final PhoneApi _phoneApi;

  SignupPhoneCheckNotifier(this._phoneApi)
    : super(const SignupPhoneCheckState());

  /// 전화번호 중복 확인
  Future<void> checkPhone(String phoneNumber) async {
    final trimmed = phoneNumber.trim();

    /// 빈 문자열이면 상태 초기화
    if (trimmed.isEmpty) {
      reset();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      checkedPhoneNumber: trimmed,
      clearAvailability: true,
      clearErrorMessage: true,
    );

    try {
      /// true  -> 이미 존재
      /// false -> 사용 가능
      final exists = await _phoneApi.checkPhoneExists(trimmed);

      state = state.copyWith(
        isLoading: false,
        checkedPhoneNumber: trimmed,
        isAvailable: !exists,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        checkedPhoneNumber: trimmed,
        errorMessage: _mapDioErrorToMessage(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        checkedPhoneNumber: trimmed,
        errorMessage: '전화번호 확인에 실패했습니다.',
      );
    }
  }

  /// 상태 초기화
  void reset() {
    state = const SignupPhoneCheckState();
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
      return '전화번호 형식이 올바르지 않습니다.';
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '네트워크 상태를 확인한 뒤 다시 시도해주세요.';
    }

    return '전화번호 확인에 실패했습니다.';
  }
}
