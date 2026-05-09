import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/onboarding_service.dart';
import '../provider/timetable_provider.dart';
import 'timetable_onboarding_page.dart';

class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({super.key});

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage> {
  List<String> _todayMemos = const [];
  int _memoWeekday = DateTime.now().weekday;
  bool _onboardingTriggered = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (kDebugMode) await OnboardingService().resetTimetableForDebug(); // TODO: remove after testing
      ref.read(timetableProvider.notifier).init();
    });
    _loadTodayMemos();
  }

  /// 시간표 데이터가 처음 로드 완료된 시점에 호출된다.
  Future<void> _maybeShowOnboarding() async {
    final isFirst = await OnboardingService().isFirstTimetableVisit();
    if (!mounted) return;
    if (!isFirst) return;
    await OnboardingService().markTimetableVisited();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const TimetableOnboardingPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableProvider);

    // 반 설정 + 시간표 로드 완료 시점에 온보딩을 트리거한다.
    ref.listen<TimetableState>(timetableProvider, (prev, next) {
      if (_onboardingTriggered) return;
      final justLoaded = next.classRoom != null &&
          !next.isLoading &&
          next.week != null &&
          (prev == null || prev.isLoading);
      if (justLoaded) {
        _onboardingTriggered = true;
        _maybeShowOnboarding();
      }
    });

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
            fontSize: 15,
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
                  _TodayMemoCard(
                    memos: _todayMemos,
                    title: '${_weekdayLabel(_memoWeekday)}요일 메모',
                    onAdd: () => _showMemoDialog(context),
                    onDelete: _deleteMemo,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _showResetConfirmDialog(context),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '시간표 되돌리기',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7D8790),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.history_rounded,
                                size: 16,
                                color: Color(0xFF7D8790),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _TimetableGrid(
                    state: state,
                    onCellLongPress: (day, period) =>
                        _showEditCellSheet(context, day, period),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _loadTodayMemos() async {
    final weekday = DateTime.now().weekday;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _memoWeekday = weekday;
      _todayMemos = prefs.getStringList(_memoStorageKey(weekday)) ?? const [];
    });
  }

  Future<void> _saveTodayMemos(List<String> memos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_memoStorageKey(_memoWeekday), memos);
  }

  Future<void> _addMemo(String memo) async {
    final trimmed = memo.trim();
    if (trimmed.isEmpty) return;

    final updated = [..._todayMemos, trimmed];
    setState(() => _todayMemos = updated);
    await _saveTodayMemos(updated);
  }

  Future<void> _deleteMemo(int index) async {
    if (index < 0 || index >= _todayMemos.length) return;

    final updated = [..._todayMemos]..removeAt(index);
    setState(() => _todayMemos = updated);
    await _saveTodayMemos(updated);
  }

  void _showMemoDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '오늘 메모',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: '예) 체육복 챙기기',
            counterText: '',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            _addMemo(value);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              _addMemo(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('추가', style: TextStyle(color: Color(0xFF14A3F7))),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '시간표를 초기화할까요?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        content: const Text(
          '직접 입력한 과목이 모두 사라지고,\n학교에서 제공한 시간표로 되돌아가요.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF444444),
            height: 1.55,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '취소',
              style: TextStyle(
                color: Color(0xFF9AA7B2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(timetableProvider.notifier).clearAllOverrides();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14A3F7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              '초기화',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCellSheet(BuildContext context, int day, int period) {
    final state = ref.read(timetableProvider);
    final key = '${day}_$period';
    final neisSubject = state.week?.subjectMap[key] ?? '';
    final overriddenSubject = state.overrides[key];
    final currentDisplay = overriddenSubject ?? neisSubject;
    final hasOverride = overriddenSubject != null;

    final controller = TextEditingController(text: currentDisplay);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 22,
          right: 22,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 행
            Row(
              children: [
                Text(
                  '${_weekdayLabel(day)}요일 $period교시',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                if (hasOverride) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '수정됨',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E8CE8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (neisSubject.isNotEmpty && hasOverride) ...[
              const SizedBox(height: 4),
              Text(
                'NEIS 원본: $neisSubject',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9AA7B2),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: 10,
              autofocus: true,
              decoration: InputDecoration(
                hintText: neisSubject.isNotEmpty ? neisSubject : '과목명 입력',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD0E4F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF14A3F7),
                    width: 1.8,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
              ),
              onSubmitted: (_) => _saveAndPop(ctx, day, period, controller.text),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (hasOverride)
                  TextButton(
                    onPressed: () {
                      ref.read(timetableProvider.notifier).clearOverride(day, period);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      '원래대로',
                      style: TextStyle(
                        color: Color(0xFFE05C5C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Color(0xFF9AA7B2)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _saveAndPop(ctx, day, period, controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14A3F7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 11,
                    ),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveAndPop(BuildContext ctx, int day, int period, String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      ref.read(timetableProvider.notifier).setOverride(day, period, trimmed);
    }
    Navigator.pop(ctx);
  }

  void _showClassRoomDialog(BuildContext context) {
    final initialClassRoom = ref.read(timetableProvider).classRoom ?? '';
    showDialog(
      context: context,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final bottomInset = media.viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: _ClassRoomDialogContent(
                  initialValue: initialClassRoom,
                  onCancel: () => Navigator.pop(ctx),
                  onSubmit: (val) {
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      ref.read(timetableProvider.notifier).setClassRoom(val);
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClassRoomDialogContent extends StatefulWidget {
  final String initialValue;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmit;

  const _ClassRoomDialogContent({
    required this.initialValue,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<_ClassRoomDialogContent> createState() => _ClassRoomDialogContentState();
}

class _ClassRoomDialogContentState extends State<_ClassRoomDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final val = _controller.text.trim();
    if (val.isEmpty) return;
    widget.onSubmit(val);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.class_rounded,
                  size: 23,
                  color: Color(0xFF14A3F7),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 반을 입력해주세요',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111111),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '학교 시간표를 불러올 때 사용돼요.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7D8790),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 2,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111111),
            ),
            decoration: InputDecoration(
              hintText: 'ex) 3',
              hintStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB0BEC5),
              ),
              suffixText: '반',
              suffixStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF52606D),
              ),
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF7FBFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDCECF7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF14A3F7),
                  width: 1.8,
                ),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFF9AA7B2),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '나중에 우측 상단 수정 버튼으로 변경할 수 있어요.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9AA7B2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7D8790),
                    side: const BorderSide(color: Color(0xFFDCECF7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14A3F7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    '시간표 보기',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              if (state.classRoom != null)
                Text(
                  '${state.week?.grade ?? '?'}학년 ${state.classRoom}반',
                  style: const TextStyle(
                    fontSize: 11,
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

class _TodayMemoCard extends StatelessWidget {
  final List<String> memos;
  final String title;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;

  const _TodayMemoCard({
    required this.memos,
    required this.title,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                if (memos.isEmpty)
                  const Text(
                    '오늘 메모 없음',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9AA7B2),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < memos.length; i++)
                        _MemoRow(memo: memos[i], onDelete: () => onDelete(i)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            color: const Color(0xFF14A3F7),
            tooltip: '메모 추가',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _MemoRow extends StatelessWidget {
  final String memo;
  final VoidCallback onDelete;

  const _MemoRow({required this.memo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.only(left: 10, right: 4, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6ECFA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              memo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF26343D),
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: Color(0xFF8A9AA7),
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
  final void Function(int day, int period) onCellLongPress;

  static const _days = ['월', '화', '수', '목', '금'];
  static const _totalPeriods = 7;

  const _TimetableGrid({
    required this.state,
    required this.onCellLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final subjectMap = state.week?.subjectMap ?? {};
    final overrides = state.overrides;
    final todayDow = DateTime.now().weekday; // 1=월~5=금

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
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
                        neisSubject: subjectMap['${d}_$p'] ?? '',
                        override: overrides['${d}_$p'],
                        isToday: d == todayDow,
                        onLongPress: () => onCellLongPress(d, p),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFFB0BEC5)),
              SizedBox(width: 4),
              Text(
                '과목 칸을 꾹 누르면 직접 수정할 수 있어요',
                style: TextStyle(fontSize: 10, color: Color(0xFFB0BEC5)),
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
            fontSize: 11,
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
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF9AA7B2),
          ),
        ),
      ),
    );
  }

  Widget _subjectCell({
    required String neisSubject,
    String? override,
    required bool isToday,
    required VoidCallback onLongPress,
  }) {
    final displaySubject = override ?? neisSubject;
    final hasOverride = override != null;
    final hasSubject = displaySubject.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(3),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onLongPress();
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFEAF7FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday
                  ? const Color(0xFFBDE8FF)
                  : const Color(0xFFE8EEF4),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  displaySubject,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasSubject ? FontWeight.w800 : FontWeight.w400,
                    color: hasSubject
                        ? const Color(0xFF333333)
                        : Colors.transparent,
                  ),
                ),
              ),
              // 수정됨 표시 도트
              if (hasOverride)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: Color(0xFF14A3F7),
                  ),
                ),
            ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE1ECF5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 34,
                  color: Color(0xFF14A3F7),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '시간표를 불러올게요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '내 반 번호를 입력하면 이번 주 시간표를 바로 확인할 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7D8790),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onSet,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('반 입력하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14A3F7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

String _weekdayLabel(int weekday) {
  const labels = ['월', '화', '수', '목', '금', '토', '일'];
  return labels[weekday - 1];
}

String _memoStorageKey(int weekday) => 'timetable_memos_weekday_$weekday';

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9AA7B2)),
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '학교 NEIS 정보가 아직 등록되지 않았어요.',
            style: TextStyle(fontSize: 11, color: Color(0xFF9AA7B2)),
          ),
        ],
      ),
    );
  }
}
