import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_verification_api.dart';
import '../models/verification_status_model.dart';
import 'admin_verification_list_state.dart';

/// 관리자 인증 요청 목록 provider
final adminVerificationListProvider =
    StateNotifierProvider<
      AdminVerificationListNotifier,
      AdminVerificationListState
    >((ref) {
      final api = ref.read(adminVerificationApiProvider);
      return AdminVerificationListNotifier(api);
    });

class AdminVerificationListNotifier
    extends StateNotifier<AdminVerificationListState> {
  final AdminVerificationApi _api;

  AdminVerificationListNotifier(this._api)
    : super(const AdminVerificationListState()) {
    fetchList();
  }

  /// 목록 조회
  Future<void> fetchList([
    VerificationStatusModel? status,
    String? keyword,
  ]) async {
    final targetStatus = status ?? state.selectedStatus;
    final nextKeyword = keyword ?? state.keyword;

    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      currentPage: 0,
      selectedStatus: targetStatus,
      keyword: nextKeyword,
      items: const [],
      clearErrorMessage: true,
    );

    try {
      final result = await _api.getRequestList(
        targetStatus,
        keyword: nextKeyword,
        page: 0,
      );

      state = state.copyWith(
        isLoading: false,
        items: result,
        hasMore: result.length >= 20,
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

  Future<void> fetchMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearErrorMessage: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _api.getRequestList(
        state.selectedStatus,
        keyword: state.keyword,
        page: nextPage,
      );

      state = state.copyWith(
        isLoadingMore: false,
        currentPage: nextPage,
        items: [...state.items, ...result],
        hasMore: result.length >= 20,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.message ?? '추가 목록 조회에 실패했습니다.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> search(String keyword) {
    return fetchList(state.selectedStatus, keyword.trim());
  }
}
