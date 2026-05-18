import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../chat/provider/chat_room_list_provider.dart';
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
    Future.microtask(() {
      ref.read(mealProvider.notifier).init();
      ref.read(chatRoomListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(mealProvider);
    final selectedDate = _parseDateKey(state.selectedDate) ?? DateTime.now();
    final weekStart = _weekStart(selectedDate);
    final weekDays = List.generate(
      5,
      (index) => weekStart.add(Duration(days: index)),
    );
    final chatUnreadCount = ref
        .watch(chatRoomListProvider)
        .rooms
        .fold(0, (sum, room) => sum + room.unreadCount);

    return Scaffold(
      backgroundColor: c.pageBg,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        chatUnreadCount: chatUnreadCount,
        onTap: (index) => _goMainTab(context, index),
      ),
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '급식',
          style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: state.error != null
          ? _ErrorState(message: state.error!)
          : !state.neisAvailable
          ? const _NeisNotConfigured()
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(mealProvider.notifier).changeWeek(weekStart),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                children: [
                  _WeekNavigator(
                    weekStart: weekStart,
                    onPrev: () => ref
                        .read(mealProvider.notifier)
                        .changeWeek(
                          weekStart.subtract(const Duration(days: 7)),
                        ),
                    onNext: () => ref
                        .read(mealProvider.notifier)
                        .changeWeek(weekStart.add(const Duration(days: 7))),
                  ),
                  const SizedBox(height: 12),
                  _WeekDayStrip(
                    days: weekDays,
                    meals: state.meals,
                    selectedDate: state.selectedDate,
                    onDateSelected: (dateKey) =>
                        ref.read(mealProvider.notifier).selectDate(dateKey),
                  ),
                  const SizedBox(height: 16),
                  if (state.isLoading)
                    const _LoadingCard()
                  else
                    _SelectedMealCard(
                      date: selectedDate,
                      meal: state.selectedMeal,
                    ),
                  const SizedBox(height: 16),
                  _WeeklySummaryCard(
                    days: weekDays,
                    meals: state.meals,
                    selectedDate: state.selectedDate,
                    onDateSelected: (dateKey) =>
                        ref.read(mealProvider.notifier).selectDate(dateKey),
                  ),
                ],
              ),
            ),
    );
  }
}

void _goMainTab(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go(AppRoutes.school);
      return;
    case 1:
      context.go(AppRoutes.chat);
      return;
    case 2:
      return;
    case 3:
      context.go(AppRoutes.timetable);
      return;
    case 4:
      context.go(AppRoutes.profile);
      return;
  }
}

class _WeekNavigator extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _WeekNavigator({
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final weekEnd = weekStart.add(const Duration(days: 4));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          _CircleArrowButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
          Expanded(
            child: Column(
              children: [
                Text(
                  '이번 주 급식',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14A3F7),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_monthDay(weekStart)} - ${_monthDay(weekEnd)}',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _CircleArrowButton(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _WeekDayStrip extends StatelessWidget {
  final List<DateTime> days;
  final Map<String, MealModel> meals;
  final String? selectedDate;
  final ValueChanged<String> onDateSelected;

  const _WeekDayStrip({
    required this.days,
    required this.meals,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: _WeekDayTile(
                date: day,
                hasMeal: meals.containsKey(_dateKey(day)),
                selected: selectedDate == _dateKey(day),
                today: _isSameDay(day, DateTime.now()),
                onTap: () => onDateSelected(_dateKey(day)),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekDayTile extends StatelessWidget {
  final DateTime date;
  final bool hasMeal;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  const _WeekDayTile({
    required this.date,
    required this.hasMeal,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final foreground = selected ? Colors.white : c.textPrimary;
    final subColor = selected ? Colors.white70 : c.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 76,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF14A3F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: today && !selected
                ? const Color(0xFF14A3F7)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdayLabel(date),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: subColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${date.day}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: foreground,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: hasMeal
                    ? selected
                          ? Colors.white
                          : const Color(0xFF14A3F7)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedMealCard extends StatelessWidget {
  final DateTime date;
  final MealModel? meal;

  const _SelectedMealCard({required this.date, required this.meal});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF14A3F7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_monthDay(date)} ${_weekdayLabel(date)}요일',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '중식',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (meal != null && meal!.calories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.tintBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    meal!.calories,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14A3F7),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (meal == null || meal!.dishes.isEmpty)
            const _EmptyMealInline()
          else
            ...meal!.dishes.map(
              (dish) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF14A3F7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dish,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: c.textBody,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final List<DateTime> days;
  final Map<String, MealModel> meals;
  final String? selectedDate;
  final ValueChanged<String> onDateSelected;

  const _WeeklySummaryCard({
    required this.days,
    required this.meals,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 주 한눈에 보기',
            style: AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 10),
          for (final day in days)
            _WeeklySummaryRow(
              date: day,
              meal: meals[_dateKey(day)],
              selected: selectedDate == _dateKey(day),
              onTap: () => onDateSelected(_dateKey(day)),
            ),
        ],
      ),
    );
  }
}

class _WeeklySummaryRow extends StatelessWidget {
  final DateTime date;
  final MealModel? meal;
  final bool selected;
  final VoidCallback onTap;

  const _WeeklySummaryRow({
    required this.date,
    required this.meal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final summary = meal == null || meal!.dishes.isEmpty
        ? '급식 없음'
        : meal!.dishes.take(3).join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.tintBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF14A3F7) : c.subtleBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _weekdayLabel(date),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : c.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: meal == null ? c.textTertiary : c.textBody,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: c.tintBg, shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF14A3F7), size: 24),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyMealInline extends StatelessWidget {
  const _EmptyMealInline();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.no_meals_rounded, size: 42, color: c.iconSecondary),
            const SizedBox(height: 10),
            Text(
              '이 날짜에는 급식 정보가 없어요.',
              style: AppTextStyles.labelSmall.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeisNotConfigured extends StatelessWidget {
  const _NeisNotConfigured();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off_rounded, size: 48, color: c.iconSecondary),
          const SizedBox(height: 12),
          Text(
            '급식 서비스가 연결되지 않았어요',
            style: AppTextStyles.labelMedium.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '학교 NEIS 정보가 아직 등록되지 않았어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 10,
              color: c.textTertiary,
            ),
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
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 11,
            color: c.textTertiary,
          ),
        ),
      ),
    );
  }
}

DateTime _weekStart(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - DateTime.monday));
}

DateTime? _parseDateKey(String? key) {
  if (key == null || key.length != 8) return null;
  final year = int.tryParse(key.substring(0, 4));
  final month = int.tryParse(key.substring(4, 6));
  final day = int.tryParse(key.substring(6, 8));
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

String _dateKey(DateTime date) {
  return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}

String _monthDay(DateTime date) {
  return '${date.month}.${date.day}';
}

String _weekdayLabel(DateTime date) {
  const labels = ['월', '화', '수', '목', '금', '토', '일'];
  return labels[date.weekday - 1];
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
