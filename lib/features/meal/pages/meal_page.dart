import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/meal_model.dart';
import '../provider/meal_provider.dart';

class MealPage extends ConsumerStatefulWidget {
  const MealPage({super.key});

  @override
  ConsumerState<MealPage> createState() => _MealPageState();
}

class _MealPageState extends ConsumerState<MealPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(mealProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F9FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.black87,
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '급식',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _MonthNavigator(
            focusedMonth: state.focusedMonth,
            onPrev: () => ref.read(mealProvider.notifier)
                .changeMonth(DateTime(state.focusedMonth.year, state.focusedMonth.month - 1)),
            onNext: () => ref.read(mealProvider.notifier)
                .changeMonth(DateTime(state.focusedMonth.year, state.focusedMonth.month + 1)),
          ),
          _CalendarGrid(
            focusedMonth: state.focusedMonth,
            meals: state.meals,
            selectedDate: state.selectedDate,
            onDateSelected: (key) => ref.read(mealProvider.notifier).selectDate(key),
          ),
          const Divider(height: 1, color: Color(0xFFE0E9F0)),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _ErrorState(message: state.error!)
                    : !state.neisAvailable
                        ? const _NeisNotConfigured()
                        : _MealDetail(meal: state.selectedMeal),
          ),
        ],
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNavigator({
    required this.focusedMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFF5A8EA8),
          ),
          Text(
            '${focusedMonth.year}년 ${focusedMonth.month}월',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFF5A8EA8),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final Map<String, MealModel> meals;
  final String? selectedDate;
  final ValueChanged<String> onDateSelected;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.meals,
    required this.selectedDate,
    required this.onDateSelected,
  });

  String _dateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final startOffset = firstDay.weekday % 7; // 0=일 ~ 6=토

    final today = DateTime.now();
    final todayKey = _dateKey(today);

    final cells = <Widget>[];
    // 요일 헤더
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    for (final day in weekdays) {
      cells.add(Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: day == '일' ? const Color(0xFFE05C7B) : const Color(0xFF6B7C8A),
          ),
        ),
      ));
    }

    // 빈 칸
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    // 날짜 칸
    for (int d = 1; d <= lastDay.day; d++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, d);
      final key = _dateKey(date);
      final hasMeal = meals.containsKey(key);
      final isSelected = selectedDate == key;
      final isToday = key == todayKey;
      final isSunday = date.weekday == DateTime.sunday;

      cells.add(GestureDetector(
        onTap: () => onDateSelected(key),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5A8EA8) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$d',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : isSunday
                          ? const Color(0xFFE05C7B)
                          : const Color(0xFF111111),
                ),
              ),
              if (hasMeal)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white70 : const Color(0xFF5A8EA8),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        children: cells,
      ),
    );
  }
}

class _MealDetail extends StatelessWidget {
  final MealModel? meal;

  const _MealDetail({this.meal});

  @override
  Widget build(BuildContext context) {
    if (meal == null) {
      return const _EmptyMeal();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded, size: 18, color: Color(0xFF5A8EA8)),
              const SizedBox(width: 6),
              const Text(
                '오늘의 중식',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const Spacer(),
              if (meal!.calories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    meal!.calories,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A8EA8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...meal!.dishes.map((dish) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5A8EA8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dish,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF333333),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _EmptyMeal extends StatelessWidget {
  const _EmptyMeal();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_meals_rounded, size: 48, color: Color(0xFFB0BEC5)),
          SizedBox(height: 12),
          Text(
            '급식 정보가 없어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7C8A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '해당 날짜의 급식이 등록되지 않았어요.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9AA7B2)),
          ),
        ],
      ),
    );
  }
}

class _NeisNotConfigured extends StatelessWidget {
  const _NeisNotConfigured();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off_rounded, size: 48, color: Color(0xFFB0BEC5)),
          SizedBox(height: 12),
          Text(
            '급식 서비스가 연결되지 않았어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7C8A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '학교 NEIS 정보가 아직 등록되지 않았어요.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9AA7B2)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 14, color: Color(0xFF9AA7B2)),
      ),
    );
  }
}
