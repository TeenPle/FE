import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/penalty_api.dart';
import '../models/penalty_model.dart';

// ── 활성 제재 상태 (전역 — 앱 전체에서 참조) ──────────────────
class ActivePenaltyState {
  final ActivePenaltyModel? penalty;
  final bool isLoading;

  const ActivePenaltyState({this.penalty, this.isLoading = false});

  bool get isPenalized => penalty?.penalized == true;

  ActivePenaltyState copyWith({
    ActivePenaltyModel? penalty,
    bool clearPenalty = false,
    bool? isLoading,
  }) {
    return ActivePenaltyState(
      penalty: clearPenalty ? null : (penalty ?? this.penalty),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ActivePenaltyNotifier extends StateNotifier<ActivePenaltyState> {
  final PenaltyApi _api;

  ActivePenaltyNotifier(this._api) : super(const ActivePenaltyState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final penalty = await _api.getMyActivePenalty();
      state = ActivePenaltyState(penalty: penalty, isLoading: false);
    } catch (e) {
      debugPrint('[PenaltyProvider] load error: $e');
      state = ActivePenaltyState(
        penalty: ActivePenaltyModel.notPenalized(),
        isLoading: false,
      );
    }
  }
}

final activePenaltyProvider =
    StateNotifierProvider<ActivePenaltyNotifier, ActivePenaltyState>((ref) {
      return ActivePenaltyNotifier(ref.watch(penaltyApiProvider));
    });

// ── 제재 이력 (설정 > 제재 이력 화면용) ──────────────────────
class PenaltyHistoryState {
  final List<PenaltyHistoryModel> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const PenaltyHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  PenaltyHistoryState copyWith({
    List<PenaltyHistoryModel>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PenaltyHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class PenaltyHistoryNotifier extends StateNotifier<PenaltyHistoryState> {
  final PenaltyApi _api;

  PenaltyHistoryNotifier(this._api) : super(const PenaltyHistoryState());

  Future<void> load() async {
    state = const PenaltyHistoryState(isLoading: true);
    try {
      final items = await _api.getMyPenaltyHistory(page: 0);
      state = PenaltyHistoryState(
        items: items,
        isLoading: false,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = const PenaltyHistoryState(
        isLoading: false,
        error: '제재 이력을 불러올 수 없어요.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final items = await _api.getMyPenaltyHistory(page: nextPage);
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoading: false,
        currentPage: nextPage,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final penaltyHistoryProvider =
    StateNotifierProvider<PenaltyHistoryNotifier, PenaltyHistoryState>((ref) {
      return PenaltyHistoryNotifier(ref.watch(penaltyApiProvider));
    });
