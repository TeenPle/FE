import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/verification_reapply_api.dart';
import '../models/verification_reapply_info_request_model.dart';
import '../models/verification_reapply_request_model.dart';
import 'verification_reapply_state.dart';

/// 반려 사유 조회 / 재요청 provider
final verificationReapplyProvider = StateNotifierProvider<
    VerificationReapplyNotifier, VerificationReapplyState>(
      (ref) {
    final api = ref.read(verificationReapplyApiProvider);
    return VerificationReapplyNotifier(api);
  },
);

class VerificationReapplyNotifier
    extends StateNotifier<VerificationReapplyState> {
  final VerificationReapplyApi _api;

  VerificationReapplyNotifier(this._api)
      : super(const VerificationReapplyState());

  /// 반려 사유 조회
  Future<void> fetchInfo({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      state = state.copyWith(
        errorMessage: '로그인 정보가 없어 반려 사유를 조회할 수 없습니다.',
      );
      return;
    }

    state = state.copyWith(
      isInfoLoading: true,
      clearErrorMessage: true,
      clearSubmitErrorMessage: true,
      isSubmitSuccess: false,
    );

    try {
      final result = await _api.getReapplyInfo(
        VerificationReapplyInfoRequestModel(
          email: trimmedEmail,
          password: trimmedPassword,
        ),
      );

      state = state.copyWith(
        isInfoLoading: false,
        info: result,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isInfoLoading: false,
        errorMessage: _mapDioErrorToMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isInfoLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// 파일 선택 상태 저장
  void setSelectedFilePath(String filePath) {
    state = state.copyWith(
      selectedFilePath: filePath,
      clearSubmitErrorMessage: true,
      isSubmitSuccess: false,
    );
  }

  /// 재요청
  Future<void> submit({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (state.info == null) {
      state = state.copyWith(
        submitErrorMessage: '반려 정보를 먼저 불러와주세요.',
      );
      return;
    }

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      state = state.copyWith(
        submitErrorMessage: '로그인 정보가 없어 재요청할 수 없습니다.',
      );
      return;
    }

    if (state.selectedFilePath.trim().isEmpty) {
      state = state.copyWith(
        submitErrorMessage: '학생증 이미지를 선택해주세요.',
      );
      return;
    }

    state = state.copyWith(
      isSubmitLoading: true,
      clearSubmitErrorMessage: true,
      isSubmitSuccess: false,
    );

    try {
      await _api.reapply(
        request: VerificationReapplyRequestModel(
          email: trimmedEmail,
          password: trimmedPassword,
          schoolId: state.info!.schoolId,
        ),
        studentCardFilePath: state.selectedFilePath,
      );

      state = state.copyWith(
        isSubmitLoading: false,
        isSubmitSuccess: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isSubmitLoading: false,
        submitErrorMessage: _mapDioErrorToMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitLoading: false,
        submitErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const VerificationReapplyState();
  }

  String? _extractBackendMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final directMessage = data['message'];
    if (directMessage is String && directMessage.trim().isNotEmpty) {
      return directMessage.trim();
    }

    final result = data['result'];
    if (result is Map<String, dynamic>) {
      final nestedMessage = result['message'];
      if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
        return nestedMessage.trim();
      }
    }

    return null;
  }

  String _mapDioErrorToMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = _extractBackendMessage(e.response?.data);

    if (message != null && message.isNotEmpty) {
      return message;
    }

    if (statusCode == 400) {
      return '입력값을 다시 확인해주세요.';
    }

    if (statusCode == 404) {
      return '사용자 또는 학교 정보를 찾을 수 없습니다.';
    }

    if (statusCode == 409) {
      return '이미 심사중인 요청이 있습니다.';
    }

    if (statusCode == 500) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '네트워크 상태를 확인한 뒤 다시 시도해주세요.';
    }

    return '처리에 실패했습니다. 다시 시도해주세요.';
  }
}