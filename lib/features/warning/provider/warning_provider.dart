import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/warning_api.dart';
import '../models/warning_model.dart';

class UnreadWarningState {
  final UnreadWarningModel? warning;
  final bool isLoading;

  const UnreadWarningState({this.warning, this.isLoading = false});

  bool get hasUnread => warning != null;

  UnreadWarningState copyWith({
    UnreadWarningModel? warning,
    bool? isLoading,
    bool clear = false,
  }) {
    return UnreadWarningState(
      warning: clear ? null : (warning ?? this.warning),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UnreadWarningNotifier extends StateNotifier<UnreadWarningState> {
  final WarningApi _api;

  UnreadWarningNotifier(this._api) : super(const UnreadWarningState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final warning = await _api.getUnreadWarning();
      state = UnreadWarningState(warning: warning, isLoading: false);
    } catch (e) {
      debugPrint('[WarningProvider] load error: $e');
      state = const UnreadWarningState(isLoading: false);
    }
  }

  Future<void> markRead(int warningId) async {
    try {
      await _api.markWarningRead(warningId);
      state = state.copyWith(clear: true);
    } catch (e) {
      debugPrint('[WarningProvider] markRead error: $e');
    }
  }
}

final unreadWarningProvider =
    StateNotifierProvider<UnreadWarningNotifier, UnreadWarningState>((ref) {
      return UnreadWarningNotifier(ref.watch(warningApiProvider));
    });

// ── 내 경고 이력 ────────────────────────────────────────────

class WarningHistoryState {
  final List<WarningHistoryModel> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const WarningHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  WarningHistoryState copyWith({
    List<WarningHistoryModel>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return WarningHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class WarningHistoryNotifier extends StateNotifier<WarningHistoryState> {
  final WarningApi _api;

  WarningHistoryNotifier(this._api) : super(const WarningHistoryState());

  Future<void> load() async {
    state = const WarningHistoryState(isLoading: true);
    try {
      final items = await _api.getMyWarnings(page: 0);
      state = WarningHistoryState(
        items: items,
        isLoading: false,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = const WarningHistoryState(
        isLoading: false,
        error: '경고 이력을 불러올 수 없어요.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final items = await _api.getMyWarnings(page: nextPage);
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

final warningHistoryProvider =
    StateNotifierProvider<WarningHistoryNotifier, WarningHistoryState>((ref) {
      return WarningHistoryNotifier(ref.watch(warningApiProvider));
    });
