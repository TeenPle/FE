import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/token_storage.dart';
import '../api/timetable_api.dart';
import '../models/timetable_model.dart';

class TimetableState {
  final TimetableWeek? week;
  final DateTime focusedWeekStart; // 해당 주 월요일
  final String? classRoom; // 저장된 반 번호
  final bool isLoading;
  final String? error;

  /// 사용자가 직접 수정한 과목. key: "${dayOfWeek}_${period}", value: 커스텀 과목명
  final Map<String, String> overrides;

  const TimetableState({
    this.week,
    required this.focusedWeekStart,
    this.classRoom,
    this.isLoading = false,
    this.error,
    this.overrides = const {},
  });

  TimetableState copyWith({
    TimetableWeek? week,
    DateTime? focusedWeekStart,
    String? classRoom,
    bool? isLoading,
    String? error,
    Map<String, String>? overrides,
  }) {
    return TimetableState(
      week: week ?? this.week,
      focusedWeekStart: focusedWeekStart ?? this.focusedWeekStart,
      classRoom: classRoom ?? this.classRoom,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      overrides: overrides ?? this.overrides,
    );
  }
}

class TimetableNotifier extends StateNotifier<TimetableState> {
  final TimetableApi _api;
  final TokenStorage _storage;

  static const _overridePrefix = 'timetable_subject_override_';

  TimetableNotifier(this._api, this._storage)
    : super(TimetableState(focusedWeekStart: _thisMonday()));

  static DateTime _thisMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  Future<void> init() async {
    await _loadOverrides();
    final saved = await _storage.getClassRoom();
    if (saved != null) {
      state = state.copyWith(classRoom: saved);
      await _fetchWeek(state.focusedWeekStart, saved);
    }
  }

  Future<void> setClassRoom(String classRoom) async {
    await _storage.saveClassRoom(classRoom);
    state = state.copyWith(classRoom: classRoom);
    await _fetchWeek(state.focusedWeekStart, classRoom);
  }

  Future<void> prevWeek() async {
    final prev = state.focusedWeekStart.subtract(const Duration(days: 7));
    state = state.copyWith(focusedWeekStart: prev);
    if (state.classRoom != null) await _fetchWeek(prev, state.classRoom!);
  }

  Future<void> nextWeek() async {
    final next = state.focusedWeekStart.add(const Duration(days: 7));
    state = state.copyWith(focusedWeekStart: next);
    if (state.classRoom != null) await _fetchWeek(next, state.classRoom!);
  }

  /// day/period에 커스텀 과목명을 저장한다. 모든 주에 동일하게 적용된다.
  Future<void> setOverride(int day, int period, String subject) async {
    final mapKey = '${day}_$period';
    final prefs = await SharedPreferences.getInstance();
    final updated = Map<String, String>.from(state.overrides);
    if (subject.isEmpty) {
      await prefs.remove('$_overridePrefix$mapKey');
      updated.remove(mapKey);
    } else {
      await prefs.setString('$_overridePrefix$mapKey', subject);
      updated[mapKey] = subject;
    }
    state = state.copyWith(overrides: updated);
  }

  Future<void> clearOverride(int day, int period) async {
    await setOverride(day, period, '');
  }

  /// 사용자가 직접 수정한 모든 과목을 초기화하고 NEIS 데이터로 되돌린다.
  Future<void> clearAllOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final toRemove = prefs
        .getKeys()
        .where((k) => k.startsWith(_overridePrefix))
        .toList();
    for (final key in toRemove) {
      await prefs.remove(key);
    }
    state = state.copyWith(overrides: {});
  }

  Future<void> _loadOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final overrides = <String, String>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_overridePrefix)) {
        final mapKey = key.substring(_overridePrefix.length);
        final val = prefs.getString(key);
        if (val != null && val.isNotEmpty) overrides[mapKey] = val;
      }
    }
    state = state.copyWith(overrides: overrides);
  }

  Future<void> _fetchWeek(DateTime monday, String classRoom) async {
    final friday = monday.add(const Duration(days: 4));
    state = state.copyWith(isLoading: true, error: null);
    try {
      final week = await _api.getTimetable(
        classRoom: classRoom,
        from: _toParam(monday),
        to: _toParam(friday),
      );
      state = state.copyWith(week: week, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '시간표를 불러올 수 없어요.');
    }
  }

  String _toParam(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}

final timetableProvider =
    StateNotifierProvider<TimetableNotifier, TimetableState>((ref) {
      return TimetableNotifier(
        ref.watch(timetableApiProvider),
        ref.watch(tokenStorageProvider),
      );
    });
