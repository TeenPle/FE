import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_warning_api.dart';
import '../models/warning_history_model.dart';

class AdminUserWarningState {
  final List<AdminWarningHistoryModel> items;
  final bool isLoading;
  final String? error;

  const AdminUserWarningState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
}

class AdminUserWarningNotifier extends StateNotifier<AdminUserWarningState> {
  final AdminWarningApi _api;
  final int userId;

  AdminUserWarningNotifier(this._api, this.userId)
    : super(const AdminUserWarningState());

  Future<void> load() async {
    state = const AdminUserWarningState(isLoading: true);
    try {
      final items = await _api.getWarningsByUser(userId);
      state = AdminUserWarningState(items: items);
    } catch (_) {
      state = const AdminUserWarningState(
        isLoading: false,
        error: '경고 이력을 불러올 수 없어요.',
      );
    }
  }
}

final adminUserWarningProvider =
    StateNotifierProvider.family<
      AdminUserWarningNotifier,
      AdminUserWarningState,
      int
    >((ref, userId) {
      return AdminUserWarningNotifier(
        ref.watch(adminWarningApiProvider),
        userId,
      );
    });
