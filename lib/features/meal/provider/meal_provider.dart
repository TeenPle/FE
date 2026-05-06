import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../api/meal_api.dart';
import '../models/meal_model.dart';

class MealState {
  final Map<String, MealModel> meals;
  final DateTime focusedMonth;
  final String? selectedDate;
  final bool isLoading;
  final String? error;
  final bool neisAvailable;

  const MealState({
    this.meals = const {},
    required this.focusedMonth,
    this.selectedDate,
    this.isLoading = false,
    this.error,
    this.neisAvailable = true,
  });

  MealState copyWith({
    Map<String, MealModel>? meals,
    DateTime? focusedMonth,
    String? selectedDate,
    bool? isLoading,
    String? error,
    bool? neisAvailable,
  }) {
    return MealState(
      meals: meals ?? this.meals,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      neisAvailable: neisAvailable ?? this.neisAvailable,
    );
  }

  MealModel? get selectedMeal =>
      selectedDate != null ? meals[selectedDate] : null;
}

class MealNotifier extends StateNotifier<MealState> {
  final MealApi _api;
  final TokenStorage _storage;
  final Set<String> _loadedRanges = {};

  MealNotifier(this._api, this._storage)
    : super(
        MealState(
          focusedMonth: _weekStart(DateTime.now()),
          selectedDate: _todayKey(),
        ),
      );

  Future<void> init() async {
    final today = DateTime.now();
    final currentWeekStart = _weekStart(today);
    state = state.copyWith(
      focusedMonth: currentWeekStart,
      selectedDate: _toDateParam(today),
    );

    await _fetchTwoWeeksIfNeeded(currentWeekStart);
  }

  Future<void> changeMonth(DateTime month) async {
    state = state.copyWith(focusedMonth: month);
    await _fetchTwoWeeksIfNeeded(_weekStart(month));
  }

  Future<void> changeWeek(DateTime weekStart) async {
    state = state.copyWith(
      focusedMonth: weekStart,
      selectedDate: _toDateParam(weekStart),
    );

    await _fetchTwoWeeksIfNeeded(weekStart);
  }

  Future<void> selectDate(String dateKey) async {
    state = state.copyWith(selectedDate: dateKey);
    if (dateKey.length != 8) return;

    final year = int.tryParse(dateKey.substring(0, 4));
    final month = int.tryParse(dateKey.substring(4, 6));
    final day = int.tryParse(dateKey.substring(6, 8));
    if (year == null || month == null || day == null) return;

    await _fetchTwoWeeksIfNeeded(_weekStart(DateTime(year, month, day)));
  }

  Future<void> _fetchTwoWeeksIfNeeded(DateTime weekStart) async {
    final normalizedStart = _weekStart(weekStart);
    final rangeEnd = normalizedStart.add(const Duration(days: 11));
    await _fetchRangeIfNeeded(normalizedStart, rangeEnd);
  }

  Future<void> _fetchRangeIfNeeded(DateTime fromDate, DateTime toDate) async {
    final from = _toDateParam(fromDate);
    final to = _toDateParam(toDate);
    final key = '${from}_$to';
    if (_loadedRanges.contains(key)) return;

    final schoolId = await _storage.getSchoolId();
    if (schoolId == null) {
      state = state.copyWith(
        isLoading: false,
        error: '학교 정보를 찾을 수 없어요. 다시 로그인해 주세요.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.getMeals(
        schoolId: schoolId,
        from: from,
        to: to,
      );

      final updated = Map<String, MealModel>.from(state.meals);
      for (final meal in response.meals) {
        updated[meal.date] = meal;
      }
      _loadedRanges.add(key);

      state = state.copyWith(
        meals: updated,
        isLoading: false,
        neisAvailable: response.neisAvailable,
        selectedDate: state.selectedDate ?? _todayKey(),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '급식 정보를 불러올 수 없어요.');
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    return _toDateParam(now);
  }

  static String _toDateParam(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static DateTime _weekStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
  }
}

final mealProvider = StateNotifierProvider<MealNotifier, MealState>((ref) {
  return MealNotifier(
    ref.watch(mealApiProvider),
    ref.watch(tokenStorageProvider),
  );
});
