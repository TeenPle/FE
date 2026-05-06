import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/timetable_model.dart';
import '../provider/timetable_provider.dart';

class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({super.key});

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(timetableProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableProvider);

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
          '시간표',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: Color(0xFF14A3F7),
            ),
            onPressed: () => _showClassRoomDialog(context),
            tooltip: '반 변경',
          ),
        ],
      ),
      body: state.classRoom == null
          ? _ClassRoomPrompt(onSet: () => _showClassRoomDialog(context))
          : state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? _ErrorState(message: state.error!)
          : (state.week != null && !state.week!.neisAvailable)
          ? const _NeisNotConfigured()
          : RefreshIndicator(
              onRefresh: () => ref.read(timetableProvider.notifier).init(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                children: [
                  _WeekNavigator(state: state),
                  const SizedBox(height: 12),
                  _TodayLastPeriodCard(state: state),
                  const SizedBox(height: 16),
                  _TimetableGrid(state: state),
                ],
              ),
            ),
    );
  }

  void _showClassRoomDialog(BuildContext context) {
    final controller = TextEditingController(
      text: ref.read(timetableProvider).classRoom ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '반 입력',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 2,
          decoration: const InputDecoration(
            hintText: '예) 3',
            counterText: '',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                ref.read(timetableProvider.notifier).setClassRoom(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('확인', style: TextStyle(color: Color(0xFF14A3F7))),
          ),
        ],
      ),
    );
  }
}

class _WeekNavigator extends ConsumerWidget {
  final TimetableState state;

  const _WeekNavigator({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monday = state.focusedWeekStart;
    final friday = monday.add(const Duration(days: 4));

    String label;
    if (monday.month == friday.month) {
      label = '${monday.month}월 ${monday.day}일 ~ ${friday.day}일';
    } else {
      label = '${monday.month}/${monday.day} ~ ${friday.month}/${friday.day}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1ECF5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => ref.read(timetableProvider.notifier).prevWeek(),
          ),
          Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              if (state.classRoom != null)
                Text(
                  '${state.week?.grade ?? '?'}학년 ${state.classRoom}반',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9AA7B2),
                  ),
                ),
            ],
          ),
          _CircleArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => ref.read(timetableProvider.notifier).nextWeek(),
          ),
        ],
      ),
    );
  }
}

class _TodayLastPeriodCard extends StatelessWidget {
  final TimetableState state;

  const _TodayLastPeriodCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isSchoolDay =
        today.weekday >= DateTime.monday && today.weekday <= DateTime.friday;
    final periods = isSchoolDay
        ? _periodsForDay(state.week?.periods ?? const [], today.weekday)
        : const <TimetablePeriod>[];
    final lastPeriod = periods.isEmpty ? null : periods.last.period;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1ECF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 19,
              color: Color(0xFF14A3F7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _todayLastPeriodText(
                isSchoolDay: isSchoolDay,
                weekday: today.weekday,
                lastPeriod: lastPeriod,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
                height: 1.25,
              ),
            ),
          ),
          if (lastPeriod != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$lastPeriod교시',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14A3F7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimetableGrid extends StatelessWidget {
  final TimetableState state;
  static const _days = ['월', '화', '수', '목', '금'];
  static const _totalPeriods = 7;

  const _TimetableGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final subjectMap = state.week?.subjectMap ?? {};
    final today = DateTime.now();
    final todayDow = today.weekday; // 1=월~5=금

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {0: FixedColumnWidth(34)},
            children: [
              TableRow(
                children: [
                  const SizedBox(height: 30),
                  for (int i = 0; i < _days.length; i++)
                    _headerCell(_days[i], highlight: (i + 1) == todayDow),
                ],
              ),
              for (int p = 1; p <= _totalPeriods; p++)
                TableRow(
                  children: [
                    _periodCell(p),
                    for (int d = 1; d <= 5; d++)
                      _subjectCell(
                        subjectMap['${d}_$p'] ?? '',
                        isToday: d == todayDow,
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFEAF7FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: highlight
                ? const Color(0xFF14A3F7)
                : const Color(0xFF6B7C8A),
          ),
        ),
      ),
    );
  }

  Widget _periodCell(int period) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$period',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF9AA7B2),
          ),
        ),
      ),
    );
  }

  Widget _subjectCell(String subject, {bool isToday = false}) {
    final hasSubject = subject.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFFEAF7FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? const Color(0xFFBDE8FF) : const Color(0xFFE8EEF4),
          ),
        ),
        child: Center(
          child: Text(
            subject,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: hasSubject ? FontWeight.w800 : FontWeight.w400,
              color: hasSubject ? const Color(0xFF333333) : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassRoomPrompt extends StatelessWidget {
  final VoidCallback onSet;

  const _ClassRoomPrompt({required this.onSet});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.class_outlined, size: 52, color: Color(0xFFB0BEC5)),
          const SizedBox(height: 16),
          const Text(
            '반을 설정해주세요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '시간표를 보려면 내 반 번호가 필요해요.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9AA7B2)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14A3F7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '반 입력하기',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF7FF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF14A3F7), size: 24),
      ),
    );
  }
}

List<TimetablePeriod> _periodsForDay(
  List<TimetablePeriod> periods,
  int dayOfWeek,
) {
  final result =
      periods
          .where(
            (period) =>
                period.dayOfWeek == dayOfWeek && period.subject.isNotEmpty,
          )
          .toList()
        ..sort((a, b) => a.period.compareTo(b.period));
  return result;
}

String _weekdayLabel(int dayOfWeek) {
  const labels = ['월', '화', '수', '목', '금', '토', '일'];
  return labels[dayOfWeek - 1];
}

String _todayLastPeriodText({
  required bool isSchoolDay,
  required int weekday,
  required int? lastPeriod,
}) {
  if (!isSchoolDay) {
    return '오늘은 수업이 없는 날이에요.';
  }
  if (lastPeriod == null) {
    return '오늘 등록된 시간표가 없어요.';
  }
  return '오늘 ${_weekdayLabel(weekday)}요일은 $lastPeriod교시까지 있어요.';
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

class _NeisNotConfigured extends StatelessWidget {
  const _NeisNotConfigured();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off_rounded, size: 52, color: Color(0xFFB0BEC5)),
          SizedBox(height: 16),
          Text(
            '시간표 서비스가 연결되지 않았어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '학교 NEIS 정보가 아직 등록되지 않았어요.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9AA7B2)),
          ),
        ],
      ),
    );
  }
}
