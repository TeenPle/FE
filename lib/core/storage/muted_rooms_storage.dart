import 'package:shared_preferences/shared_preferences.dart';

/// 채팅방별 알림 OFF 목록을 로컬에 저장/불러오는 저장소.
/// Set<int> 형태로 관리하며 roomId 단위로 on/off 를 기록한다.
class MutedRoomsStorage {
  static const _key = 'muted_room_ids';

  Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((s) => int.tryParse(s)).whereType<int>().toSet();
  }

  Future<void> save(Set<int> roomIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, roomIds.map((id) => '$id').toList());
  }
}
