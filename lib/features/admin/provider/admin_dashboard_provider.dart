import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_report_api.dart';
import '../api/admin_verification_api.dart';

class AdminDashboardState {
  final int? pendingVerificationCount;
  final int? pendingReportCount;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.pendingVerificationCount,
    this.pendingReportCount,
    this.isLoading = false,
    this.error,
  });

  AdminDashboardState copyWith({
    int? pendingVerificationCount,
    int? pendingReportCount,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      pendingVerificationCount:
          pendingVerificationCount ?? this.pendingVerificationCount,
      pendingReportCount: pendingReportCount ?? this.pendingReportCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminVerificationApi _verificationApi;
  final AdminReportApi _reportApi;

  AdminDashboardNotifier(this._verificationApi, this._reportApi)
      : super(const AdminDashboardState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait<int>([
        _verificationApi.getPendingRequestCount(),
        _reportApi.getPendingReportCount(),
      ]);
      state = state.copyWith(
        pendingVerificationCount: results[0],
        pendingReportCount: results[1],
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: '관리자 대기 건수를 불러오지 못했습니다.',
      );
    }
  }
}

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
  return AdminDashboardNotifier(
    ref.watch(adminVerificationApiProvider),
    ref.watch(adminReportApiProvider),
  );
});
