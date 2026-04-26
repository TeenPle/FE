import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/token_storage.dart';
import '../api/timetable_api.dart';
import '../models/timetable_model.dart';

class TimetableState {
  final TimetableWeek? week;
  final DateTime focusedWeekStart; // 해당 주 월요일
  final String? classRoom;         // 저장된 반 번호
  final bool isLoading;
  final String? error;

  const TimetableState({
    this.week,
    required this.focusedWeekStart,
    this.classRoom,
    this.isLoading = false,
    this.error,
  });

  TimetableState copyWith({
    TimetableWeek? week,
    DateTime? focusedWeekStart,
    String? classRoom,
    bool? isLoading,
    String? error,
  }) {
    return TimetableState(
      week: week ?? this.week,
      focusedWeekStart: focusedWeekStart ?? this.focusedWeekStart,
      classRoom: classRoom ?? this.classRoom,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TimetableNotifier extends StateNotifier<TimetableState> {
  final TimetableApi _api;
  final TokenStorage _storage;

  TimetableNotifier(this._api, this._storage)
      : super(TimetableState(focusedWeekStart: _thisMonday()));

  static DateTime _thisMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  Future<void> init() async {
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
