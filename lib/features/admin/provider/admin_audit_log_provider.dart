import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_audit_log_api.dart';
import '../models/admin_audit_log_model.dart';

class AdminAuditLogState {
  final List<AdminAuditLogModel> logs;
  final int page;
  final String? action;
  final String? targetType;
  final int? adminId;
  final DateTime? from;
  final DateTime? to;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const AdminAuditLogState({
    this.logs = const [],
    this.page = 0,
    this.action,
    this.targetType,
    this.adminId,
    this.from,
    this.to,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  AdminAuditLogState copyWith({
    List<AdminAuditLogModel>? logs,
    int? page,
    String? action,
    String? targetType,
    int? adminId,
    DateTime? from,
    DateTime? to,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return AdminAuditLogState(
      logs: logs ?? this.logs,
      page: page ?? this.page,
      action: action ?? this.action,
      targetType: targetType ?? this.targetType,
      adminId: adminId ?? this.adminId,
      from: from ?? this.from,
      to: to ?? this.to,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class AdminAuditLogNotifier extends StateNotifier<AdminAuditLogState> {
  final AdminAuditLogApi _api;

  AdminAuditLogNotifier(this._api) : super(const AdminAuditLogState());

  Future<void> load({
    String? action,
    String? targetType,
    int? adminId,
    DateTime? from,
    DateTime? to,
  }) async {
    final nextAction = action ?? state.action;
    final nextTargetType = targetType ?? state.targetType;
    final nextAdminId = adminId ?? state.adminId;
    final nextFrom = from ?? state.from;
    final nextTo = to ?? state.to;
    state = state.copyWith(page: 0, isLoading: true, hasMore: true, error: null);
    try {
      final logs = await _api.getLogs(
        action: nextAction,
        targetType: nextTargetType,
        adminId: nextAdminId,
        from: nextFrom,
        to: nextTo,
      );
      state = state.copyWith(
        logs: logs,
        action: nextAction,
        targetType: nextTargetType,
        adminId: nextAdminId,
        from: nextFrom,
        to: nextTo,
        isLoading: false,
        hasMore: logs.length == 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '감사 로그를 불러오지 못했습니다.');
    }
  }

  Future<void> clearFilters() async {
    state = const AdminAuditLogState(isLoading: true);
    try {
      final logs = await _api.getLogs();
      state = state.copyWith(
        logs: logs,
        isLoading: false,
        hasMore: logs.length == 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '감사 로그를 불러오지 못했습니다.');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final logs = await _api.getLogs(
        page: nextPage,
        action: state.action,
        targetType: state.targetType,
        adminId: state.adminId,
        from: state.from,
        to: state.to,
      );
      state = state.copyWith(
        logs: [...state.logs, ...logs],
        page: nextPage,
        isLoadingMore: false,
        hasMore: logs.length == 20,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false, error: '추가 감사 로그를 불러오지 못했습니다.');
    }
  }
}

final adminAuditLogProvider =
    StateNotifierProvider<AdminAuditLogNotifier, AdminAuditLogState>((ref) {
  return AdminAuditLogNotifier(ref.watch(adminAuditLogApiProvider));
});
