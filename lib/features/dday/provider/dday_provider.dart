import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dday_model.dart';

class DDayNotifier extends StateNotifier<List<DDayModel>> {
  static const _key = 'dday_list_v1';

  DDayNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        state = DDayModel.decodeList(raw);
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, DDayModel.encodeList(state));
  }

  Future<void> add(DDayModel dday) async {
    state = [...state, dday];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((d) => d.id != id).toList();
    await _save();
  }

  Future<void> update(DDayModel dday) async {
    state = state.map((d) => d.id == dday.id ? dday : d).toList();
    await _save();
  }
}

final ddayProvider = StateNotifierProvider<DDayNotifier, List<DDayModel>>(
  (_) => DDayNotifier(),
);
