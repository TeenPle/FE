import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../inquiry/api/admin_inquiry_api.dart';
import '../../inquiry/models/inquiry_model.dart';
import '../api/admin_report_api.dart';
import '../api/admin_verification_api.dart';
import '../models/report_summary_model.dart';
import '../models/verification_request_list_item_model.dart';
import '../models/verification_status_model.dart';

enum AdminDashboardEventType { verification, report, inquiry }

class AdminDashboardEvent {
  final AdminDashboardEventType type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final String route;

  const AdminDashboardEvent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.route,
  });
}

class AdminDashboardState {
  final int? pendingVerificationCount;
  final int? pendingReportCount;
  final int? pendingInquiryCount;
  final List<AdminDashboardEvent> recentEvents;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.pendingVerificationCount,
    this.pendingReportCount,
    this.pendingInquiryCount,
    this.recentEvents = const [],
    this.isLoading = false,
    this.error,
  });

  AdminDashboardState copyWith({
    int? pendingVerificationCount,
    int? pendingReportCount,
    int? pendingInquiryCount,
    List<AdminDashboardEvent>? recentEvents,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      pendingVerificationCount:
          pendingVerificationCount ?? this.pendingVerificationCount,
      pendingReportCount: pendingReportCount ?? this.pendingReportCount,
      pendingInquiryCount: pendingInquiryCount ?? this.pendingInquiryCount,
      recentEvents: recentEvents ?? this.recentEvents,
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
      final results = await Future.wait<Object>([
        _verificationApi.getPendingRequestCount(),
        _reportApi.getPendingReportCount(),
        _inquiryApi.getPendingInquiryCount(),
        _verificationApi.getRequestList(
          VerificationStatusModel.pending,
          size: 2,
        ),
        _reportApi.getReports(status: 'PENDING', size: 2),
        _inquiryApi.getInquiries(status: 'PENDING', size: 2),
      ]);
      state = state.copyWith(
        pendingVerificationCount: results[0] as int,
        pendingReportCount: results[1] as int,
        pendingInquiryCount: results[2] as int,
        recentEvents: _buildRecentEvents(
          verificationItems:
              results[3] as List<VerificationRequestListItemModel>,
          reportItems: results[4] as List<ReportSummaryModel>,
          inquiryItems: results[5] as List<InquirySummaryModel>,
        ),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '관리자 대기 건수를 불러오지 못했어요.');
    }
  }

  List<AdminDashboardEvent> _buildRecentEvents({
    required List<VerificationRequestListItemModel> verificationItems,
    required List<ReportSummaryModel> reportItems,
    required List<InquirySummaryModel> inquiryItems,
  }) {
    final events = <AdminDashboardEvent>[
      ...verificationItems.map(
        (item) => AdminDashboardEvent(
          type: AdminDashboardEventType.verification,
          title: '학교 인증 요청',
          subtitle: '${item.userName} · ${item.schoolName}',
          createdAt: item.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          route: '${AppRoutes.adminVerificationList}/${item.requestId}',
        ),
      ),
      ...reportItems.map(
        (item) => AdminDashboardEvent(
          type: AdminDashboardEventType.report,
          title: '신고 접수',
          subtitle: '${item.targetTypeLabel} · ${item.reportedUserNickname}',
          createdAt: item.createdAt,
          route: AppRoutes.adminReportDetail(item.reportId),
        ),
      ),
      ...inquiryItems.map(
        (item) => AdminDashboardEvent(
          type: AdminDashboardEventType.inquiry,
          title: '문의 접수',
          subtitle: item.title,
          createdAt: item.createdAt,
          route: AppRoutes.adminInquiryDetail(item.inquiryId),
        ),
      ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return events.take(5).toList(growable: false);
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
