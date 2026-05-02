import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../api/block_api.dart';
import '../models/blocked_user_model.dart';

final blockApiProvider = Provider<BlockApi>((ref) {
  return BlockApi(client: AppApiClient(ref.watch(dioProvider)));
});

// ─────────────────────────────────────────────
// 차단 목록
// ─────────────────────────────────────────────

class BlockedUsersNotifier extends StateNotifier<AsyncValue<List<BlockedUserModel>>> {
  final BlockApi _api;

  BlockedUsersNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.getBlockedUsers());
  }

  Future<void> unblock(int userId) async {
    await _api.unblockUser(userId);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((u) => u.userId != userId).toList());
  }
}

final blockedUsersProvider =
    StateNotifierProvider<BlockedUsersNotifier, AsyncValue<List<BlockedUserModel>>>((ref) {
  return BlockedUsersNotifier(ref.watch(blockApiProvider));
});

// ─────────────────────────────────────────────
// 단건 차단 액션 (게시글/댓글 3-dot 메뉴용)
// ─────────────────────────────────────────────

final blockActionProvider = Provider<BlockAction>((ref) {
  return BlockAction(ref.watch(blockApiProvider));
});

class BlockAction {
  final BlockApi _api;
  const BlockAction(this._api);

  Future<void> block(int userId) => _api.blockUser(userId);
}
