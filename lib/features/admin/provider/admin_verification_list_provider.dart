import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_verification_api.dart';
import '../models/verification_status_model.dart';
import 'admin_verification_list_state.dart';

/// 관리자 인증 요청 목록 provider
final adminVerificationListProvider = StateNotifierProvider<
    AdminVerificationListNotifier, AdminVerificationListState>(
      (ref) {
    final api = ref.read(adminVerificationApiProvider);
    return AdminVerificationListNotifier(api);
  },
);

class AdminVerificationListNotifier
    extends StateNotifier<AdminVerificationListState> {
  final AdminVerificationApi _api;

  AdminVerificationListNotifier(this._api)
      : super(const AdminVerificationListState()) {
    fetchList();
  }

  /// 목록 조회
  Future<void> fetchList([VerificationStatusModel? status]) async {
    final targetStatus = status ?? state.selectedStatus;

    state = state.copyWith(
      isLoading: true,
      selectedStatus: targetStatus,
      clearErrorMessage: true,
    );

    try {
      final result = await _api.getRequestList(targetStatus);

      state = state.copyWith(
        isLoading: false,
        items: result,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        items: const [],
        errorMessage: e.message ?? '목록 조회에 실패했습니다.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        items: const [],
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}