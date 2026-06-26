import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/muted_rooms_storage.dart';

final _mutedRoomsStorageProvider = Provider<MutedRoomsStorage>((ref) {
  return MutedRoomsStorage();
});

/// 알림이 꺼진 채팅방 ID 집합. SharedPreferences에 영구 저장된다.
final mutedRoomsProvider = StateNotifierProvider<MutedRoomsNotifier, Set<int>>((
  ref,
) {
  return MutedRoomsNotifier(ref.read(_mutedRoomsStorageProvider));
});

class MutedRoomsNotifier extends StateNotifier<Set<int>> {
  final MutedRoomsStorage _storage;

  MutedRoomsNotifier(this._storage) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.load();
  }

  bool isMuted(int roomId) => state.contains(roomId);

  Future<void> toggle(int roomId) async {
    final next = isMuted(roomId)
        ? state.where((id) => id != roomId).toSet()
        : {...state, roomId};
    state = next;
    await _storage.save(next);
  }
}
