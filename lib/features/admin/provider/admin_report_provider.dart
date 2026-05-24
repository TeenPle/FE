import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_report_api.dart';
import '../models/report_summary_model.dart';

class AdminReportListState {
  final List<ReportSummaryModel> reports;
  final String activeStatus;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String keyword;
  final String? error;

  const AdminReportListState({
    this.reports = const [],
    this.activeStatus = 'PENDING',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.keyword = '',
    this.error,
  });

  AdminReportListState copyWith({
    List<ReportSummaryModel>? reports,
    String? activeStatus,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? keyword,
    String? error,
  }) {
    return AdminReportListState(
      reports: reports ?? this.reports,
      activeStatus: activeStatus ?? this.activeStatus,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      keyword: keyword ?? this.keyword,
      error: error,
    );
  }
}

class AdminReportListNotifier extends StateNotifier<AdminReportListState> {
  final AdminReportApi _api;

  AdminReportListNotifier(this._api) : super(const AdminReportListState());

  Future<void> load({String status = 'PENDING', String? keyword}) async {
    final nextKeyword = keyword ?? state.keyword;
    state = state.copyWith(
      reports: const [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      currentPage: 0,
      activeStatus: status,
      keyword: nextKeyword,
      error: null,
    );
    try {
      final reports = await _api.getReports(
        status: status,
        keyword: nextKeyword,
        page: 0,
      );
      state = state.copyWith(
        reports: reports,
        isLoading: false,
        hasMore: reports.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '신고 목록을 불러오지 못했어요.');
    }
  }

  Future<void> refresh() => load(status: state.activeStatus);

  Future<void> search(String keyword) {
    return load(status: state.activeStatus, keyword: keyword.trim());
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final nextPage = state.currentPage + 1;
      final reports = await _api.getReports(
        status: state.activeStatus,
        keyword: state.keyword,
        page: nextPage,
      );

      state = state.copyWith(
        reports: [...state.reports, ...reports],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: reports.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        error: '추가 신고 목록을 불러오지 못했습니다.',
      );
    }
  }
}

final adminReportListProvider =
    StateNotifierProvider<AdminReportListNotifier, AdminReportListState>((ref) {
      return AdminReportListNotifier(ref.watch(adminReportApiProvider));
    });

class AdminReportDetailState {
  final ReportDetailModel? detail;
  final bool isLoading;
  final bool isActing;
  final String? error;
  final String? successMessage;

  const AdminReportDetailState({
    this.detail,
    this.isLoading = false,
    this.isActing = false,
    this.error,
    this.successMessage,
  });

  AdminReportDetailState copyWith({
    ReportDetailModel? detail,
    bool? isLoading,
    bool? isActing,
    String? error,
    String? successMessage,
  }) {
    return AdminReportDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      isActing: isActing ?? this.isActing,
      error: error,
      successMessage: successMessage,
    );
  }
}

class AdminReportDetailNotifier extends StateNotifier<AdminReportDetailState> {
  final AdminReportApi _api;
  final int reportId;

  AdminReportDetailNotifier(this._api, this.reportId)
    : super(const AdminReportDetailState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final detail = await _api.getReportDetail(reportId);
      state = state.copyWith(detail: detail, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '신고 정보를 불러오지 못했어요.');
    }
  }

  Future<bool> approve(int penaltyDays, String adminComment) async {
    state = state.copyWith(isActing: true, error: null, successMessage: null);
    try {
      await _api.approveReport(reportId, penaltyDays, adminComment);
      state = state.copyWith(isActing: false, successMessage: '제재를 적용했어요.');
      return true;
    } catch (_) {
      state = state.copyWith(isActing: false, error: '승인 처리에 실패했어요.');
      return false;
    }
  }

  Future<bool> reject(String adminComment) async {
    state = state.copyWith(isActing: true, error: null, successMessage: null);
    try {
      await _api.rejectReport(reportId, adminComment);
      state = state.copyWith(isActing: false, successMessage: '신고를 거절했어요.');
      return true;
    } catch (_) {
      state = state.copyWith(isActing: false, error: '거절 처리에 실패했어요.');
      return false;
    }
  }

  Future<bool> warn(String adminComment) async {
    state = state.copyWith(isActing: true, error: null, successMessage: null);
    try {
      await _api.warnReport(reportId, adminComment);
      state = state.copyWith(isActing: false, successMessage: '경고를 발령했어요.');
      return true;
    } catch (_) {
      state = state.copyWith(isActing: false, error: '경고 발령에 실패했어요.');
      return false;
    }
  }
}

final adminReportDetailProvider =
    StateNotifierProvider.family<
      AdminReportDetailNotifier,
      AdminReportDetailState,
      int
    >((ref, reportId) {
      return AdminReportDetailNotifier(
        ref.watch(adminReportApiProvider),
        reportId,
      );
    });
