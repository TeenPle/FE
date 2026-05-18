import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_penalty_api.dart';
import '../models/penalty_summary_model.dart';

class AdminPenaltyListState {
  final List<PenaltySummaryModel> penalties;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const AdminPenaltyListState({
    this.penalties = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  AdminPenaltyListState copyWith({
    List<PenaltySummaryModel>? penalties,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return AdminPenaltyListState(
      penalties: penalties ?? this.penalties,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class AdminPenaltyListNotifier extends StateNotifier<AdminPenaltyListState> {
  final AdminPenaltyApi _api;

  AdminPenaltyListNotifier(this._api) : super(const AdminPenaltyListState());

  Future<void> load() async {
    state = const AdminPenaltyListState(isLoading: true);
    try {
      final items = await _api.getAllPenalties(page: 0);
      state = AdminPenaltyListState(
        penalties: items,
        isLoading: false,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = const AdminPenaltyListState(
        isLoading: false,
        error: '제재 내역을 불러올 수 없어요.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final items = await _api.getAllPenalties(page: nextPage);
      state = state.copyWith(
        penalties: [...state.penalties, ...items],
        isLoading: false,
        currentPage: nextPage,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> cancel(int penaltyId) async {
    try {
      await _api.cancelPenalty(penaltyId);
      // 목록에서 해당 항목의 status를 CANCELLED로 변경
      final updated = state.penalties.map((p) {
        if (p.penaltyId == penaltyId) {
          return PenaltySummaryModel(
            penaltyId: p.penaltyId,
            userId: p.userId,
            userNickname: p.userNickname,
            reportId: p.reportId,
            reason: p.reason,
            status: 'CANCELLED',
            expiresAt: p.expiresAt,
            createdAt: p.createdAt,
          );
        }
        return p;
      }).toList();
      state = state.copyWith(penalties: updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminPenaltyListProvider =
    StateNotifierProvider<AdminPenaltyListNotifier, AdminPenaltyListState>((
      ref,
    ) {
      return AdminPenaltyListNotifier(ref.watch(adminPenaltyApiProvider));
    });

// ── 유저별 제재 이력 ─────────────────────────────────────────

class AdminUserPenaltyNotifier extends StateNotifier<AdminPenaltyListState> {
  final AdminPenaltyApi _api;
  final int userId;

  AdminUserPenaltyNotifier(this._api, this.userId)
    : super(const AdminPenaltyListState());

  Future<void> load() async {
    state = const AdminPenaltyListState(isLoading: true);
    try {
      final items = await _api.getPenaltiesByUser(userId);
      state = AdminPenaltyListState(
        penalties: items,
        isLoading: false,
        hasMore: false,
      );
    } catch (_) {
      state = const AdminPenaltyListState(
        isLoading: false,
        error: '제재 이력을 불러올 수 없어요.',
      );
    }
  }
}

final adminUserPenaltyProvider =
    StateNotifierProvider.family<
      AdminUserPenaltyNotifier,
      AdminPenaltyListState,
      int
    >((ref, userId) {
      return AdminUserPenaltyNotifier(
        ref.watch(adminPenaltyApiProvider),
        userId,
      );
    });
