import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF5A8EA8)),
            onPressed: () => _showClassRoomDialog(context),
            tooltip: '반 변경',
          ),
        ],
      ),
      body: state.classRoom == null
          ? _ClassRoomPrompt(onSet: () => _showClassRoomDialog(context))
          : Column(
              children: [
                _WeekNavigator(state: state),
                const SizedBox(height: 4),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.error != null
                          ? _ErrorState(message: state.error!)
                          : (state.week != null && !state.week!.neisAvailable)
                              ? const _NeisNotConfigured()
                              : _TimetableGrid(state: state),
                ),
              ],
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
        title: const Text('반 입력', style: TextStyle(fontWeight: FontWeight.w700)),
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
            child: const Text('확인', style: TextStyle(color: Color(0xFF5A8EA8))),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => ref.read(timetableProvider.notifier).prevWeek(),
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFF5A8EA8),
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
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9AA7B2)),
                ),
            ],
          ),
          IconButton(
            onPressed: () => ref.read(timetableProvider.notifier).nextWeek(),
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFF5A8EA8),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Table(
        border: TableBorder.all(color: const Color(0xFFDDE6ED), width: 0.8),
        columnWidths: const {
          0: FixedColumnWidth(36),
        },
        children: [
          // 요일 헤더
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEAF3FB)),
            children: [
              _headerCell(''),
              for (int i = 0; i < _days.length; i++)
                _headerCell(
                  _days[i],
                  highlight: (i + 1) == todayDow,
                ),
            ],
          ),
          // 교시 행
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
    );
  }

  Widget _headerCell(String text, {bool highlight = false}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? const Color(0xFF5A8EA8) : const Color(0xFF6B7C8A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodCell(int period) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: const Color(0xFFF0F5FA),
        child: Center(
          child: Text(
            '$period',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9AA7B2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _subjectCell(String subject, {bool isToday = false}) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        color: isToday
            ? const Color(0xFFF0F8FF)
            : Colors.white,
        child: Center(
          child: Text(
            subject,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: subject.isNotEmpty ? FontWeight.w500 : FontWeight.w400,
              color: subject.isNotEmpty
                  ? const Color(0xFF333333)
                  : const Color(0xFFDDE6ED),
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
              backgroundColor: const Color(0xFF5A8EA8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('반 입력하기', style: TextStyle(fontWeight: FontWeight.w700)),
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
