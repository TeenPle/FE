import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../form/board_tab_bar.dart';
import '../models/board_model.dart';

/// 최초 접속 시 표시되는 온보딩 튜토리얼 페이지.
/// 목 데이터로 학교 메인 화면을 재현하고, 고정 레이아웃에서 코치마크를 실행해
/// 스포트라이트 위치를 픽셀 단위로 정확하게 유지한다.
class SchoolOnboardingPage extends StatefulWidget {
  const SchoolOnboardingPage({super.key});

  @override
  State<SchoolOnboardingPage> createState() => _SchoolOnboardingPageState();
}

class _SchoolOnboardingPageState extends State<SchoolOnboardingPage> {
  final _boardTabKey = GlobalKey();
  final _hotHeaderKey = GlobalKey();
  final _fabKey = GlobalKey();
  final _bottomNavKey = GlobalKey();

  static final _mockBoards = [
    const BoardModel(id: 1, title: '자유', description: '', active: true),
    const BoardModel(id: 2, title: '공지', description: '', active: true),
    const BoardModel(id: 3, title: '질문', description: '', active: true),
    const BoardModel(id: 4, title: '정보', description: '', active: true),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTutorial());
  }

  void _startTutorial() {
    if (!mounted) return;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'board_tab',
        keyTarget: _boardTabKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _CoachContent(
              title: '📋 게시판 탭',
              body: '탭을 눌러 게시판을 선택해요.\n선택한 게시판의 최신 게시글을 미리볼 수 있어요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'hot_section',
        keyTarget: _hotHeaderKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _CoachContent(
              title: '🔥 HOT 게시판',
              body: '좋아요를 많이 받은 인기글 모음이에요.\n오늘 · 이번 주 · 이번 달로 필터할 수 있어요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'fab',
        keyTarget: _fabKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _CoachContent(
              title: '✏️ 글쓰기',
              body: '이 버튼으로 현재 게시판에\n글을 작성할 수 있어요.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'bottom_nav',
        keyTarget: _bottomNavKey,
        shape: ShapeLightFocus.RRect,
        radius: 30,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _CoachContent(
              title: '하단 메뉴',
              body: '채팅 · 급식 · 시간표 · 내정보를\n여기서 바로 이동할 수 있어요.',
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
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: null,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF444444),
        shape: const CircleBorder(),
        elevation: 2,
        child: const Icon(Icons.edit_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNavBar(
        key: _bottomNavKey,
        currentIndex: 0,
        onTap: (_) {},
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMockHeader(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E6EA)),
            BoardTabBar(
              key: _boardTabKey,
              boards: _mockBoards,
              selectedBoardId: 1,
              onBoardSelected: (_) {},
            ),
            Expanded(
              child: _MockContent(hotHeaderKey: _hotHeaderKey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockHeader() {
    return Container(
      color: const Color(0xFFF3F9FF),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF9A9A9A),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '우리 학교',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          const Icon(Icons.search, size: 28, color: Colors.black87),
          const SizedBox(width: 12),
          const Icon(Icons.notifications_none, size: 28, color: Colors.black87),
        ],
      ),
    );
  }
}

/// 스크롤 없는 고정 콘텐츠 영역.
/// SingleChildScrollView + NeverScrollableScrollPhysics 조합으로
/// 오버플로 없이 내용을 클리핑한다.
class _MockContent extends StatelessWidget {
  final GlobalKey hotHeaderKey;

  const _MockContent({required this.hotHeaderKey});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 최신글 섹션
          Container(
            margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              children: [
                _MockPostTile(
                  title: '수능 D-100인데 다들 어떻게 공부하고 있어요?',
                  meta: '5분 전  ·  익명',
                  likes: 12,
                  comments: 8,
                  showDivider: true,
                ),
                _MockPostTile(
                  title: '오늘 급식 진짜 맛있지 않았나요? 치킨까스 퀄리티 ㄷㄷ',
                  meta: '23분 전  ·  익명',
                  likes: 21,
                  comments: 6,
                  showDivider: true,
                ),
                _MockPostTile(
                  title: '학교 축제 날짜 아는 사람 있어요?',
                  meta: '1시간 전  ·  익명',
                  likes: 5,
                  comments: 3,
                  showDivider: false,
                ),
              ],
            ),
          ),

          // HOT 섹션 헤더 — 코치마크 타겟
          Padding(
            key: hotHeaderKey,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                const Text(
                  'HOT 게시판',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                const Spacer(),
                _HotFilterChip(label: '오늘', selected: true),
                const SizedBox(width: 6),
                _HotFilterChip(label: '이번 주', selected: false),
                const SizedBox(width: 6),
                _HotFilterChip(label: '이번 달', selected: false),
              ],
            ),
          ),

          // HOT 게시글
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              children: [
                _MockPostTile(
                  title: '수학 공부 꿀팁 모음 (진짜 효과있음)',
                  meta: '어제  ·  익명',
                  likes: 47,
                  comments: 23,
                  showDivider: true,
                ),
                _MockPostTile(
                  title: '급식 메뉴 추천 건의해봅시다',
                  meta: '2일 전  ·  익명',
                  likes: 38,
                  comments: 15,
                  showDivider: true,
                ),
                _MockPostTile(
                  title: '학교 안 숨겨진 공부 스팟 알려줌',
                  meta: '3일 전  ·  공부왕',
                  likes: 25,
                  comments: 11,
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockPostTile extends StatelessWidget {
  final String title;
  final String meta;
  final int likes;
  final int comments;
  final bool showDivider;

  const _MockPostTile({
    required this.title,
    required this.meta,
    required this.likes,
    required this.comments,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E8E),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 15,
                    color: Color(0xFFFF8E98),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$likes',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF8E98),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 15,
                    color: Color(0xFF66BFF5),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$comments',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF66BFF5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFDCDCDC)),
      ],
    );
  }
}

class _HotFilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _HotFilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF6B35) : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF9AA7B2),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
