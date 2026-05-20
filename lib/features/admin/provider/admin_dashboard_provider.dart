import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inquiry/api/admin_inquiry_api.dart';
import '../api/admin_report_api.dart';
import '../api/admin_verification_api.dart';

class AdminDashboardState {
  final int? pendingVerificationCount;
  final int? pendingReportCount;
  final int? pendingInquiryCount;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.pendingVerificationCount,
    this.pendingReportCount,
    this.pendingInquiryCount,
    this.isLoading = false,
    this.error,
  });

  AdminDashboardState copyWith({
    int? pendingVerificationCount,
    int? pendingReportCount,
    int? pendingInquiryCount,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      pendingVerificationCount:
          pendingVerificationCount ?? this.pendingVerificationCount,
      pendingReportCount: pendingReportCount ?? this.pendingReportCount,
      pendingInquiryCount: pendingInquiryCount ?? this.pendingInquiryCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminVerificationApi _verificationApi;
  final AdminReportApi _reportApi;
  final AdminInquiryApi _inquiryApi;

  AdminDashboardNotifier(
    this._verificationApi,
    this._reportApi,
    this._inquiryApi,
  ) : super(const AdminDashboardState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final countResults = await Future.wait<int>([
        _verificationApi.getPendingRequestCount(),
        _reportApi.getPendingReportCount(),
        _inquiryApi.getPendingInquiryCount(),
      ]);
      state = state.copyWith(
        pendingVerificationCount: countResults[0],
        pendingReportCount: countResults[1],
        pendingInquiryCount: countResults[2],
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '관리자 대기 건수를 불러오지 못했습니다.');
    }
  }
}

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
      return AdminDashboardNotifier(
        ref.watch(adminVerificationApiProvider),
        ref.watch(adminReportApiProvider),
        ref.watch(adminInquiryApiProvider),
      );
    });
