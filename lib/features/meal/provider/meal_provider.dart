import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/token_storage.dart';
import '../api/meal_api.dart';
import '../models/meal_model.dart';

class MealState {
  final Map<String, MealModel> meals; // key: "20260425"
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

  MealModel? get selectedMeal => selectedDate != null ? meals[selectedDate] : null;
}

class MealNotifier extends StateNotifier<MealState> {
  final MealApi _api;
  final TokenStorage _storage;
  final Set<String> _loadedMonths = {};

  MealNotifier(this._api, this._storage)
      : super(MealState(
          focusedMonth: DateTime.now(),
          selectedDate: _todayKey(),
        ));

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  static String _monthKey(DateTime month) =>
      '${month.year}${month.month.toString().padLeft(2, '0')}';

  Future<void> init() async {
    await _fetchMonthIfNeeded(state.focusedMonth);
  }

  Future<void> changeMonth(DateTime month) async {
    state = state.copyWith(focusedMonth: month);
    await _fetchMonthIfNeeded(month);
  }

  void selectDate(String dateKey) {
    state = state.copyWith(selectedDate: dateKey);
  }

  Future<void> _fetchMonthIfNeeded(DateTime month) async {
    final key = _monthKey(month);
    if (_loadedMonths.contains(key)) return;

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
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);
      final from = _toDateParam(firstDay);
      final to = _toDateParam(lastDay);

      final response = await _api.getMeals(schoolId: schoolId, from: from, to: to);
      final updated = Map<String, MealModel>.from(state.meals);
      for (final meal in response.meals) {
        updated[meal.date] = meal;
      }
      _loadedMonths.add(key);

      // 선택 날짜에 급식이 없으면 이번 달 가장 가까운 급식 있는 날로 자동 이동
      String? newSelectedDate = state.selectedDate;
      if (newSelectedDate == null || !updated.containsKey(newSelectedDate)) {
        final today = _todayKey();
        // 오늘 이전 날짜 중 급식 있는 가장 최근 날, 없으면 이후 날짜 중 가장 빠른 날
        final sorted = updated.keys.toList()..sort();
        newSelectedDate = sorted.lastWhere((d) => d.compareTo(today) <= 0,
            orElse: () => sorted.isNotEmpty ? sorted.first : today);
      }

      state = state.copyWith(
        meals: updated,
        isLoading: false,
        neisAvailable: response.neisAvailable,
        selectedDate: newSelectedDate,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '급식 정보를 불러올 수 없어요.');
    }
  }

  String _toDateParam(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}

final mealProvider = StateNotifierProvider<MealNotifier, MealState>((ref) {
  return MealNotifier(
    ref.watch(mealApiProvider),
    ref.watch(tokenStorageProvider),
  );
});
