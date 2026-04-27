import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/warning_api.dart';
import '../models/warning_model.dart';

class UnreadWarningState {
  final UnreadWarningModel? warning;
  final bool isLoading;

  const UnreadWarningState({this.warning, this.isLoading = false});

  bool get hasUnread => warning != null;

  UnreadWarningState copyWith({UnreadWarningModel? warning, bool? isLoading, bool clear = false}) {
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
