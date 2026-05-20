import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../chat/provider/chat_room_list_provider.dart';
import '../provider/timetable_provider.dart';

class TimetableMemo {
  final String time;
  final String text;

  const TimetableMemo({required this.time, required this.text});

  factory TimetableMemo.fromStored(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return TimetableMemo(
          time: decoded['time'] as String? ?? '',
          text: decoded['text'] as String? ?? '',
        );
      }
    } catch (_) {
      // Older app versions stored plain memo text.
    }
    return TimetableMemo(time: '시간 없음', text: value);
  }

  String toStored() => jsonEncode({'time': time, 'text': text});
}

class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({super.key});

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage> {
  List<TimetableMemo> _todayMemos = const [];
  int _memoWeekday = DateTime.now().weekday;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(timetableProvider.notifier).init();
      ref.read(chatRoomListProvider.notifier).load();
    });
    _loadTodayMemos();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableProvider);
    final chatUnreadCount = ref
        .watch(chatRoomListProvider)
        .rooms
        .fold(0, (sum, room) => sum + room.unreadCount);

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        chatUnreadCount: chatUnreadCount,
        onTap: (index) => _goMainTab(context, index),
      ),
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '시간표',
          style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '시간표 되돌리기',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: c.textMuted,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.history_rounded,
                                size: 16,
                                color: c.textMuted,
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
                    selectedWeekday: _memoWeekday,
                    onDayTap: _selectMemoWeekday,
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
    final memos = _decodeStoredMemos(
      prefs.getStringList(_memoStorageKey(weekday)) ?? const [],
    );
    if (!mounted) return;
    setState(() {
      _memoWeekday = weekday;
      _todayMemos = memos;
    });
  }

  List<TimetableMemo> _decodeStoredMemos(List<String> values) {
    return values
        .map(TimetableMemo.fromStored)
        .where((memo) => memo.text.trim().isNotEmpty)
        .toList();
  }

  Future<void> _selectMemoWeekday(int weekday) async {
    if (weekday < 1 || weekday > 5 || weekday == _memoWeekday) return;
    final prefs = await SharedPreferences.getInstance();
    final memos = _decodeStoredMemos(
      prefs.getStringList(_memoStorageKey(weekday)) ?? const [],
    );
    if (!mounted) return;
    setState(() {
      _memoWeekday = weekday;
      _todayMemos = memos;
    });
  }

  Future<void> _saveTodayMemos(List<TimetableMemo> memos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _memoStorageKey(_memoWeekday),
      memos.map((memo) => memo.toStored()).toList(),
    );
  }

  Future<void> _addMemo(TimetableMemo memo) async {
    final trimmed = memo.text.trim();
    if (trimmed.isEmpty) return;

    final updated = [
      ..._todayMemos,
      TimetableMemo(time: memo.time, text: trimmed),
    ]..sort((a, b) => a.time.compareTo(b.time));
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemoBottomSheet(onSubmit: _addMemo),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final bc = ctx.colors;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            '시간표를 초기화할까요?',
            style: AppTextStyles.titleSmall.copyWith(color: bc.textPrimary),
          ),
          content: Text(
            '직접 입력한 과목이 모두 사라지고,\n학교에서 제공한 시간표로 되돌아가요.',
            style: AppTextStyles.captionSmall.copyWith(
              color: bc.textBody,
              height: 1.55,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '취소',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: bc.textMuted,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                '초기화',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditCellSheet(BuildContext context, int day, int period) {
    final state = ref.read(timetableProvider);
    final key = '${day}_$period';
    final neisSubject = state.week?.subjectMap[key] ?? '';
    final overriddenSubject = state.overrides[key];
    final currentDisplay = overriddenSubject ?? neisSubject;
    final hasOverride = overriddenSubject != null;
    final sheetBg = context.colors.cardBg;

    final controller = TextEditingController(text: currentDisplay);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final bc = ctx.colors;
        return Padding(
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
              Row(
                children: [
                  Text(
                    '${_weekdayLabel(day)}요일 $period교시',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: bc.textPrimary,
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
                        color: bc.tintBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '수정됨',
                        style: AppTextStyles.bodyMedium.copyWith(
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
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 10,
                    color: bc.textMuted,
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
                    borderSide: BorderSide(color: bc.border),
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
                onSubmitted: (_) =>
                    _saveAndPop(ctx, day, period, controller.text),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (hasOverride)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(timetableProvider.notifier)
                            .clearOverride(day, period);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        '원래대로',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Color(0xFFE05C5C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      '취소',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: bc.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () =>
                        _saveAndPop(ctx, day, period, controller.text),
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
                    child: Text(
                      '저장',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final availableHeight =
            media.size.height -
            media.viewInsets.bottom -
            media.padding.top -
            16;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: availableHeight.clamp(280.0, media.size.height),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
          ),
        );
      },
    );
  }
}

class _MemoBottomSheet extends StatefulWidget {
  final ValueChanged<TimetableMemo> onSubmit;

  const _MemoBottomSheet({required this.onSubmit});

  @override
  State<_MemoBottomSheet> createState() => _MemoBottomSheetState();
}

class _MemoBottomSheetState extends State<_MemoBottomSheet> {
  late final TextEditingController _controller;
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  bool _hasText = false;
  bool _hasValidTime = true;
  bool _isPm = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    final currentTime = _splitMemoTime(_currentTimeText());
    _isPm = currentTime.isPm;
    _hourController = TextEditingController(text: currentTime.hour);
    _minuteController = TextEditingController(text: currentTime.minute);
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    void validateTime() {
      if (!mounted) return;
      final hasValidTime = _buildMemoTime() != null;
      setState(() => _hasValidTime = hasValidTime);
    }

    _hourController.addListener(validateTime);
    _minuteController.addListener(validateTime);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final time = _buildMemoTime();
    if (!_hasText || time == null) return;
    widget.onSubmit(TimetableMemo(time: time, text: _controller.text));
    Navigator.pop(context);
  }

  void _setPeriod(bool isPm) {
    if (_isPm == isPm) return;
    setState(() => _isPm = isPm);
  }

  String? _buildMemoTime() {
    final hour = int.tryParse(_hourController.text.trim());
    final minute = int.tryParse(_minuteController.text.trim());
    if (hour == null || minute == null) return null;
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;

    final hour24 = _isPm
        ? (hour == 12 ? 12 : hour + 12)
        : (hour == 12 ? 0 : hour);
    return '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.popupBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.divider,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  size: 16,
                  color: Color(0xFF14A3F7),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '메모 추가',
                style: AppTextStyles.titleMedium.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  _PeriodSegment(
                    label: '오전',
                    selected: !_isPm,
                    onTap: () => _setPeriod(false),
                  ),
                  const SizedBox(width: 5),
                  _PeriodSegment(
                    label: '오후',
                    selected: _isPm,
                    onTap: () => _setPeriod(true),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 66,
                child: _TimePartField(
                  controller: _hourController,
                  label: '시',
                  hintText: '8',
                  hasError: !_hasValidTime,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 66,
                child: _TimePartField(
                  controller: _minuteController,
                  label: '분',
                  hintText: '30',
                  hasError: !_hasValidTime,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          if (!_hasValidTime) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '시간은 1~12시, 분은 0~59 사이로 입력해 주세요',
                style: AppTextStyles.captionSmall.copyWith(
                  color: const Color(0xFFE76F6F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 36,
            style: AppTextStyles.bodyMedium.copyWith(
              color: c.textBody,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: '예) 체육복 챙기기',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: c.textHint,
                fontWeight: FontWeight.w400,
              ),
              counterText: '',
              filled: true,
              fillColor: c.inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF14A3F7),
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                gradient: _hasText && _hasValidTime
                    ? const LinearGradient(
                        colors: [Color(0xFF14A3F7), Color(0xFF0D87D4)],
                      )
                    : null,
                color: _hasText && _hasValidTime
                    ? null
                    : const Color(0xFFEAF7FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _hasText && _hasValidTime ? _submit : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Text(
                      '추가하기',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: _hasText && _hasValidTime
                            ? Colors.white
                            : const Color(0xFF14A3F7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 42,
      height: 25,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF14A3F7) : c.subtleBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selected ? const Color(0xFF14A3F7) : c.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.captionSmall.copyWith(
                fontSize: 9,
                color: selected ? Colors.white : c.textMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePartField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool hasError;
  final TextInputAction textInputAction;

  const _TimePartField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.hasError,
    required this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final borderColor = hasError ? const Color(0xFFE76F6F) : c.border;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      maxLength: 2,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      style: AppTextStyles.titleMedium.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        suffixText: label,
        suffixStyle: AppTextStyles.labelSmall.copyWith(
          color: c.textBody,
          fontWeight: FontWeight.w800,
        ),
        counterText: '',
        filled: true,
        fillColor: c.inputBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE76F6F) : const Color(0xFF14A3F7),
            width: 1.5,
          ),
        ),
      ),
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
  State<_ClassRoomDialogContent> createState() =>
      _ClassRoomDialogContentState();
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
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.class_rounded,
                  size: 18,
                  color: Color(0xFF14A3F7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 반을 입력해주세요',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '학교 시간표를 불러올 때 사용돼요.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 118,
              height: 44,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 2,
                autofocus: true,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: '3',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.textHint,
                  ),
                  suffixText: '반',
                  suffixStyle: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: c.textSecondary,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: c.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF14A3F7),
                      width: 1.4,
                    ),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13, color: c.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '나중에 우측 상단 수정 버튼으로 변경할 수 있어요.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textMuted,
                    side: BorderSide(color: c.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    '취소',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    '시간표 보기',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
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

void _goMainTab(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go(AppRoutes.school);
      return;
    case 1:
      context.go(AppRoutes.chat);
      return;
    case 2:
      context.go(AppRoutes.meal);
      return;
    case 3:
      return;
    case 4:
      context.go(AppRoutes.profile);
      return;
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

    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderStrong),
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
                style: AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
              ),
              if (state.classRoom != null)
                Text(
                  '${state.week?.grade ?? '?'}학년 ${state.classRoom}반',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 10,
                    color: c.textMuted,
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
  final List<TimetableMemo> memos;
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
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final memoBorderColor = isDark ? c.borderBlue : const Color(0xFFB9DCFF);
    final addBorderColor = isDark ? c.borderBlue : const Color(0xFF14A3F7);
    final addColor = isDark ? const Color(0xFF4DB8FF) : const Color(0xFF14A3F7);
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: memoBorderColor, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF14A3F7).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4DC3FF), Color(0xFF14A3F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: addBorderColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 13, color: addColor),
                        const SizedBox(width: 2),
                        Text(
                          '추가',
                          style: AppTextStyles.captionSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: addColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
            child: memos.isEmpty
                ? Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 13,
                        color: c.textDisabled,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '오늘 챙길 것들을 메모해보세요',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: c.textDisabled,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      for (int i = 0; i < memos.length; i++)
                        _MemoRow(
                          memo: memos[i],
                          isLast: i == memos.length - 1,
                          onDelete: () => onDelete(i),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemoRow extends StatelessWidget {
  final TimetableMemo memo;
  final bool isLast;
  final VoidCallback onDelete;

  const _MemoRow({
    required this.memo,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowBorderColor = isDark ? c.borderBlue : const Color(0xFF9DCEFF);
    final timeColor = isDark
        ? const Color(0xFF4DB8FF)
        : const Color(0xFF1498F3);
    final dividerColor = isDark ? c.dividerBlue : const Color(0xFFCBE6FF);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isLast ? 0 : 7),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? c.inputBg : c.cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: rowBorderColor, width: 0.9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 43,
            child: Text(
              memo.time,
              textAlign: TextAlign.left,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: timeColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 14, color: dividerColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              memo.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: c.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 15, color: c.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableGrid extends StatelessWidget {
  final TimetableState state;
  final int selectedWeekday;
  final ValueChanged<int> onDayTap;
  final void Function(int day, int period) onCellLongPress;

  static const _days = ['월', '화', '수', '목', '금'];
  static const _totalPeriods = 7;
  const _TimetableGrid({
    required this.state,
    required this.selectedWeekday,
    required this.onDayTap,
    required this.onCellLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subjectMap = state.week?.subjectMap ?? {};
    final overrides = state.overrides;
    final todayDow = DateTime.now().weekday; // 1=월~5=금

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final subjectColumnWidth =
                  (constraints.maxWidth - 34) / _days.length;
              final cellHeight = subjectColumnWidth.clamp(40.0, 48.0);
              final headerHeight = (cellHeight * 0.68).clamp(26.0, 32.0);
              final subjectFontSize = subjectColumnWidth < 48 ? 9.0 : 10.0;

              return Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {0: FixedColumnWidth(34)},
                children: [
                  TableRow(
                    children: [
                      SizedBox(height: headerHeight),
                      for (int i = 0; i < _days.length; i++)
                        _headerCell(
                          _days[i],
                          height: headerHeight,
                          highlight: (i + 1) == selectedWeekday,
                          isToday: (i + 1) == todayDow,
                          onTap: () => onDayTap(i + 1),
                          c: c,
                        ),
                    ],
                  ),
                  for (int p = 1; p <= _totalPeriods; p++)
                    TableRow(
                      children: [
                        _periodCell(p, c, height: cellHeight),
                        for (int d = 1; d <= 5; d++)
                          _subjectCell(
                            neisSubject: subjectMap['${d}_$p'] ?? '',
                            override: overrides['${d}_$p'],
                            isToday: d == selectedWeekday,
                            height: cellHeight,
                            fontSize: subjectFontSize,
                            onLongPress: () => onCellLongPress(d, p),
                            c: c,
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 13, color: c.textHint),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '과목 칸을 꾹 누르면 직접 수정할 수 있어요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 10,
                    color: c.textHint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCell(
    String text, {
    required double height,
    bool highlight = false,
    bool isToday = false,
    required VoidCallback onTap,
    required AppColors c,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFEAF7FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlight ? c.borderBlue : Colors.transparent,
            ),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: highlight || isToday
                  ? const Color(0xFF14A3F7)
                  : c.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodCell(int period, AppColors c, {required double height}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.subtleBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$period',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: c.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _subjectCell({
    required String neisSubject,
    String? override,
    required bool isToday,
    required double height,
    required double fontSize,
    required VoidCallback onLongPress,
    required AppColors c,
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
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isToday ? c.tintBg : c.subtleBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday ? c.borderBlue : c.border,
              width: isToday ? 1.2 : 1,
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
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: fontSize,
                    fontWeight: hasSubject ? FontWeight.w800 : FontWeight.w400,
                    color: hasSubject ? c.textPrimary : Colors.transparent,
                  ),
                ),
              ),
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
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.borderStrong),
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
              Text(
                '시간표를 불러올게요',
                style: AppTextStyles.titleLarge.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                '내 반 번호를 입력하면 이번 주 시간표를 바로 확인할 수 있어요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  height: 1.45,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onSet,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text('반 입력하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14A3F7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12,
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
        decoration: BoxDecoration(
          color: context.colors.tintBg,
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

String _currentTimeText() {
  final now = DateTime.now();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

_MemoTimeParts _splitMemoTime(String value) {
  final parts = value.split(':');
  final hour24 = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final isPm = hour24 >= 12;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return _MemoTimeParts(
    isPm: isPm,
    hour: hour12.toString(),
    minute: minute.toString().padLeft(2, '0'),
  );
}

class _MemoTimeParts {
  final bool isPm;
  final String hour;
  final String minute;

  const _MemoTimeParts({
    required this.isPm,
    required this.hour,
    required this.minute,
  });
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.captionSmall.copyWith(
          color: context.colors.textMuted,
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
          Icon(Icons.link_off_rounded, size: 52, color: c.iconMuted),
          const SizedBox(height: 16),
          Text(
            '시간표 서비스가 연결되지 않았어요',
            style: AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '학교 NEIS 정보가 아직 등록되지 않았어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 10,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
