import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 최초 접속 시 표시되는 온보딩 튜토리얼 페이지.
/// 목 데이터로 시간표 화면을 재현하고, 고정 레이아웃에서 코치마크를 실행해
/// 스포트라이트 위치를 픽셀 단위로 정확하게 유지한다.
class TimetableOnboardingPage extends StatefulWidget {
  const TimetableOnboardingPage({super.key});

  @override
  State<TimetableOnboardingPage> createState() =>
      _TimetableOnboardingPageState();
}

class _TimetableOnboardingPageState extends State<TimetableOnboardingPage> {
  final _weekNavKey = GlobalKey();
  final _memoCardKey = GlobalKey();
  final _subjectCellKey = GlobalKey();
  final _resetButtonKey = GlobalKey();

  // 목 시간표 데이터 — 수요일(day 3)을 오늘로 표시
  static const _mockTodayDow = 3;

  static const _mockSubjects = {
    '1_1': '국어',
    '1_2': '수학',
    '1_3': '영어',
    '1_4': '과학',
    '1_5': '체육',
    '1_6': '미술',
    '1_7': '수학',
    '2_1': '영어',
    '2_2': '사회',
    '2_3': '수학',
    '2_4': '체육',
    '2_5': '국어',
    '2_6': '음악',
    '2_7': '과학',
    '3_1': '수학',
    '3_2': '국어',
    '3_3': '과학',
    '3_4': '영어',
    '3_5': '사회',
    '3_6': '역사',
    '3_7': '도덕',
    '4_1': '체육',
    '4_2': '영어',
    '4_3': '국어',
    '4_4': '수학',
    '4_5': '과학',
    '4_6': '미술',
    '4_7': '음악',
    '5_1': '영어',
    '5_2': '수학',
    '5_3': '사회',
    '5_4': '도덕',
    '5_5': '체육',
    '5_6': '국어',
    '5_7': '과학',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTutorial());
  }

  void _startTutorial() {
    if (!mounted) return;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'week_nav',
        keyTarget: _weekNavKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const _CoachContent(
              title: '📅 주 이동',
              body: '화살표를 눌러 지난 주나 다음 주\n시간표를 확인할 수 있어요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'memo_card',
        keyTarget: _memoCardKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const _CoachContent(
              title: '📝 요일 메모',
              body: '+ 버튼으로 오늘 할 일을 기록해요.\n요일마다 따로 저장돼요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'subject_cell',
        keyTarget: _subjectCellKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const _CoachContent(
              title: '👆 과목 직접 수정',
              body: '과목 칸을 꾹 누르면 직접 이름을 바꿀 수 있어요.\n수정한 칸에는 파란 점이 표시돼요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'reset_button',
        keyTarget: _resetButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const _CoachContent(
              title: '↺ 시간표 초기화',
              body: '수정한 과목을 한 번에 되돌리고 싶다면\n이 버튼을 눌러요.',
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: '건너뛰기',
      textStyleSkip: AppTextStyles.labelMedium.copyWith(color: Colors.white70),
      paddingFocus: 8,
      opacityShadow: 0.85,
      onFinish: () {
        if (mounted) Navigator.pop(context);
      },
      onSkip: () {
        if (mounted) Navigator.pop(context);
        return true;
      },
    ).show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: c.textPrimary,
        ),
        title: Text(
          '시간표',
          style: AppTextStyles.titleLarge.copyWith(color: c.textPrimary),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.edit_outlined,
              size: 20,
              color: Color(0xFF14A3F7),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          child: Column(
            children: [
              _MockWeekNavigator(widgetKey: _weekNavKey),
              const SizedBox(height: 12),
              _MockMemoCard(widgetKey: _memoCardKey),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    key: _resetButtonKey,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7D8790),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: Color(0xFF7D8790),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _MockTimetableGrid(
                subjects: _mockSubjects,
                todayDow: _mockTodayDow,
                subjectCellKey: _subjectCellKey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockWeekNavigator extends StatelessWidget {
  final GlobalKey widgetKey;

  const _MockWeekNavigator({required this.widgetKey});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: widgetKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1ECF5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleArrow(icon: Icons.chevron_left_rounded),
          Column(
            children: [
              Text(
                '5월 5일 ~ 9일',
                style: AppTextStyles.titleSmall.copyWith(color: c.textPrimary),
              ),
              Text(
                '2학년 3반',
                style: AppTextStyles.captionSmall.copyWith(
                  color: Color(0xFF9AA7B2),
                ),
              ),
            ],
          ),
          _CircleArrow(icon: Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _CircleArrow extends StatelessWidget {
  final IconData icon;

  const _CircleArrow({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF7FF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF14A3F7), size: 24),
    );
  }
}

class _MockMemoCard extends StatelessWidget {
  final GlobalKey widgetKey;

  const _MockMemoCard({required this.widgetKey});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: widgetKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.cardBg,
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
                  '수요일 메모',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 4,
                    top: 8,
                    bottom: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD6ECFA)),
                  ),
                  child: Text(
                    '체육복 챙기기',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF26343D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.add_rounded, color: Color(0xFF14A3F7)),
        ],
      ),
    );
  }
}

class _MockTimetableGrid extends StatelessWidget {
  final Map<String, String> subjects;
  final int todayDow;
  final GlobalKey subjectCellKey;

  static const _days = ['월', '화', '수', '목', '금'];
  static const _totalPeriods = 7;

  const _MockTimetableGrid({
    required this.subjects,
    required this.todayDow,
    required this.subjectCellKey,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: c.cardBg,
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
                        // 수요일(day 3) 1교시 셀에 키를 부착해 코치마크 타겟으로 사용
                        cellKey: (d == 3 && p == 1) ? subjectCellKey : null,
                        subject: subjects['${d}_$p'] ?? '',
                        isToday: d == todayDow,
                        // 수요일 3교시에 수정됨 도트 표시 (편집 기능 시각적 예시)
                        hasOverride: d == 3 && p == 3,
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 13,
                color: Color(0xFFB0BEC5),
              ),
              const SizedBox(width: 4),
              Text(
                '과목 칸을 꾹 누르면 직접 수정할 수 있어요',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 10,
                  color: Color(0xFFB0BEC5),
                ),
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
          style: AppTextStyles.bodyMedium.copyWith(
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
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF9AA7B2),
          ),
        ),
      ),
    );
  }

  Widget _subjectCell({
    required String subject,
    required bool isToday,
    required bool hasOverride,
    Key? cellKey,
  }) {
    return Padding(
      key: cellKey,
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
        child: Stack(
          children: [
            Center(
              child: Text(
                subject,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 11,
                  fontWeight: subject.isNotEmpty
                      ? FontWeight.w800
                      : FontWeight.w400,
                  color: subject.isNotEmpty
                      ? const Color(0xFF333333)
                      : Colors.transparent,
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
    );
  }
}

class _CoachContent extends StatelessWidget {
  final String title;
  final String body;

  const _CoachContent({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: AppTextStyles.captionLarge.copyWith(
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
