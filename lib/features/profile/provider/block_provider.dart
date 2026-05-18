import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../api/block_api.dart';

final blockApiProvider = Provider<BlockApi>((ref) {
  return BlockApi(client: AppApiClient(ref.watch(dioProvider)));
});

final blockSummaryProvider =
    StateNotifierProvider<BlockSummaryNotifier, AsyncValue<int>>((ref) {
      final notifier = BlockSummaryNotifier(ref.watch(blockApiProvider));
      Future.microtask(notifier.load);
      return notifier;
    });

class BlockSummaryNotifier extends StateNotifier<AsyncValue<int>> {
  final BlockApi _api;

  BlockSummaryNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.getBlockedCount());
  }

  Future<void> unblockAll() async {
    await _api.unblockAll();
    state = const AsyncValue.data(0);
  }
}

final blockActionProvider = Provider<BlockAction>((ref) {
  return BlockAction(ref.watch(blockApiProvider), ref);
});

class BlockAction {
  final BlockApi _api;
  final Ref _ref;

  const BlockAction(this._api, this._ref);

  Future<void> block(int userId) async {
    await _api.blockUser(userId);
    _ref.invalidate(blockSummaryProvider);
  }
}
