import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class SchoolOnboardingPage extends StatefulWidget {
  const SchoolOnboardingPage({super.key});

  @override
  State<SchoolOnboardingPage> createState() => _SchoolOnboardingPageState();
}

class _SchoolOnboardingPageState extends State<SchoolOnboardingPage> {
  final _feedTabKey = GlobalKey();
  final _popularTabKey = GlobalKey();
  final _writeButtonKey = GlobalKey();
  final _mealNavKey = GlobalKey();
  final _timetableNavKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTutorial());
  }

  void _startTutorial() {
    if (!mounted) return;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'feed_tab',
        keyTarget: _feedTabKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const _CoachContent(
              title: '📋 피드',
              body: '학교 모든 게시판의 최신글을\n피드 탭에서 한눈에 확인해요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'popular_tab',
        keyTarget: _popularTabKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const _CoachContent(
              title: '🔥 인기',
              body: '인기 탭에서 오늘 · 이번 주 · 이번 달\n가장 반응 좋은 글만 모아볼 수 있어요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'write',
        keyTarget: _writeButtonKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const _CoachContent(
              title: '✏️ 글쓰기',
              body: '이 버튼으로 언제든\n우리 학교에 글을 올릴 수 있어요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'meal',
        keyTarget: _mealNavKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const _CoachContent(
              title: '🍱 급식',
              body: '오늘 급식 메뉴를\n바로 확인할 수 있어요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'timetable',
        keyTarget: _timetableNavKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const _CoachContent(
              title: '📅 시간표',
              body: '내 시간표를 한눈에 보고\n수업을 미리 확인해요.',
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: '건너뛰기',
      textStyleSkip: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      paddingFocus: 10,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      bottomNavigationBar: _buildMockBottomBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildMockHeader(),
            _buildMockDDayStrip(),
            _buildMockTabBar(),
            const Expanded(child: _MockFeed()),
          ],
        ),
      ),
    );
  }

  Widget _buildMockHeader() {
    return Container(
      color: const Color(0xFFF6FBFF),
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD8E8F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Color(0xFF229BF3), size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '우리 학교',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF050505),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.verified_rounded, size: 18, color: Color(0xFF229BF3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 29, color: Color(0xFF0B0B0B)),
          const SizedBox(width: 13),
          const Icon(Icons.notifications_none_rounded, size: 29, color: Color(0xFF0B0B0B)),
        ],
      ),
    );
  }

  Widget _buildMockDDayStrip() {
    return Container(
      height: 48,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'D-DAY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF229BF3)),
          ),
          const SizedBox(width: 10),
          _MockDDayChip(label: '수능', days: 'D-47'),
          const SizedBox(width: 6),
          _MockDDayChip(label: '중간고사', days: 'D-12'),
          const SizedBox(width: 6),
          _MockDDayChip(label: '방학', days: 'D-53'),
        ],
      ),
    );
  }

  Widget _buildMockTabBar() {
    return Container(
      color: const Color(0xFFF6FBFF),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          height: 40,
          width: 236,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF2F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  key: _feedTabKey,
                  decoration: BoxDecoration(
                    color: const Color(0xFF229BF3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Center(
                    child: Text(
                      '피드',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  key: _popularTabKey,
                  decoration: const BoxDecoration(),
                  child: const Center(
                    child: Text(
                      '인기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8C8F95),
                      ),
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    '게시판',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8C8F95),
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

  Widget _buildMockBottomBar() {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 28),
            child: Container(
              key: _writeButtonKey,
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFF229BF3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3314A3F7),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MockNavItem(icon: Icons.home_rounded, label: '홈', selected: true),
                _MockNavItem(icon: Icons.chat_bubble_outline_rounded, label: '채팅'),
                _MockNavItem(
                  icon: Icons.restaurant_outlined,
                  label: '급식',
                  navKey: _mealNavKey,
                ),
                _MockNavItem(
                  icon: Icons.calendar_today_outlined,
                  label: '시간표',
                  navKey: _timetableNavKey,
                ),
                _MockNavItem(icon: Icons.person_outline_rounded, label: '내정보'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockFeed extends StatelessWidget {
  const _MockFeed();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      children: const [
        _MockPostCard(
          title: '오늘 급식 레전드였음 ㅋㅋ 치킨까스 퀄리티 ㄷㄷ',
          author: '익명',
          time: '5분 전',
          category: '자유',
          categoryColor: Color(0xFFFF9E2C),
          likes: 24,
          comments: 8,
          hot: true,
        ),
        _MockPostCard(
          title: '수학 개념 설명 잘 하는 방법 아는 사람?',
          author: '공부왕',
          time: '12분 전',
          category: '질문',
          categoryColor: Color(0xFF8C63D8),
          likes: 6,
          comments: 3,
        ),
        _MockPostCard(
          title: '학교 카페 새로 생긴 아메리카노 진짜 맛있음',
          author: '카페인중독',
          time: '34분 전',
          category: '정보',
          categoryColor: Color(0xFF18A999),
          likes: 11,
          comments: 5,
        ),
        _MockPostCard(
          title: '고백했는데 차였어요 어떡하죠',
          author: '익명',
          time: '1시간 전',
          category: '연애',
          categoryColor: Color(0xFFFF5F7E),
          likes: 41,
          comments: 17,
        ),
      ],
    );
  }
}

class _MockPostCard extends StatelessWidget {
  final String title;
  final String author;
  final String time;
  final String category;
  final Color categoryColor;
  final int likes;
  final int comments;
  final bool hot;

  const _MockPostCard({
    required this.title,
    required this.author,
    required this.time,
    required this.category,
    required this.categoryColor,
    required this.likes,
    required this.comments,
    this.hot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7EAEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, size: 17, color: Color(0xFF9AA1AA)),
              ),
              const SizedBox(width: 8),
              Text(
                author,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF151515)),
              ),
              const SizedBox(width: 10),
              Text(
                time,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8F9298)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  category,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: categoryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                if (hot)
                  const TextSpan(
                    text: 'HOT ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF050505),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF229BF3)),
              const SizedBox(width: 4),
              Text('$comments', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF229BF3))),
              const SizedBox(width: 18),
              const Icon(Icons.favorite_border_rounded, size: 18, color: Color(0xFFFF5B6D)),
              const SizedBox(width: 4),
              Text('$likes', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFF5B6D))),
            ],
          ),
        ],
      ),
    );
  }
}

class _MockDDayChip extends StatelessWidget {
  final String label;
  final String days;

  const _MockDDayChip({required this.label, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF444444)),
          ),
          const SizedBox(width: 6),
          Text(
            days,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF229BF3)),
          ),
        ],
      ),
    );
  }
}

class _MockNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final GlobalKey? navKey;

  const _MockNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.navKey,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF229BF3) : const Color(0xFF282D33);
    return SizedBox(
      key: navKey,
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
