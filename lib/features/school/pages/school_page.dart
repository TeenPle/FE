import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/post_summary_skeleton.dart';
import '../../../features/auth/provider/login_provider.dart';
import '../../../features/chat/provider/chat_room_list_provider.dart';
import '../../../features/dday/widgets/dday_strip.dart';
import '../../../features/notification/provider/notification_provider.dart';
import '../../../features/notification/service/fcm_service.dart';
import '../../../features/penalty/models/penalty_model.dart';
import '../../../features/penalty/provider/penalty_provider.dart';
import '../../../features/warning/models/warning_model.dart';
import '../../../features/warning/provider/warning_provider.dart';
import '../models/board_model.dart';
import '../models/hot_filter.dart';
import '../models/post_summary.dart';
import '../provider/school_providers.dart';
import '../provider/school_state.dart';
import 'school_onboarding_page.dart';
import 'widgets/post_summary_card.dart';
import 'widgets/school_header.dart';

enum _HomeTab { feed, popular, boards }

class SchoolPage extends ConsumerStatefulWidget {
  const SchoolPage({super.key});

  @override
  ConsumerState<SchoolPage> createState() => _SchoolPageState();
}

class _SchoolPageState extends ConsumerState<SchoolPage>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  int _bottomIndex = 0;
  _HomeTab _selectedTab = _HomeTab.feed;
  bool _penaltyDialogShown = false;
  bool _warningDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);

    Future.microtask(() async {
      final dialogContext = context;

      int? schoolId = ref.read(loginProvider).loginResponse?.schoolId;
      schoolId ??= await ref.read(tokenStorageProvider).getSchoolId();

      if (schoolId != null) {
        ref.read(schoolProvider.notifier).loadInitialSchool(schoolId);
      }

      await Future.wait([
        ref.read(activePenaltyProvider.notifier).load(),
        ref.read(unreadWarningProvider.notifier).load(),
      ]);

      if (!mounted || !dialogContext.mounted) return;

      final penaltyState = ref.read(activePenaltyProvider);
      if (penaltyState.isPenalized && !_penaltyDialogShown) {
        _penaltyDialogShown = true;
        _showPenaltyDialog(dialogContext, penaltyState.penalty!);
        return;
      }

      final warningState = ref.read(unreadWarningProvider);
      if (warningState.hasUnread && !_warningDialogShown) {
        _warningDialogShown = true;
        _showWarningDialog(dialogContext, warningState.warning!);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fcm = ref.read(fcmServiceProvider);
      fcm.init().catchError((e) {
        if (kDebugMode) debugPrint('[FCM ERROR] $e');
      });
      fcm.handleInitialMessage();
      ref.read(notificationProvider.notifier).loadUnreadCount();
      ref.read(chatRoomListProvider.notifier).load();
      ref.read(chatRoomListProvider.notifier).startRealtime();

      if (kDebugMode) await OnboardingService().resetForDebug();
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted || _penaltyDialogShown || _warningDialogShown) return;

      final onboardingSvc = OnboardingService();
      final isFirst = await onboardingSvc.isFirstSchoolVisit();
      if (!mounted) return;
      if (isFirst) {
        await onboardingSvc.markSchoolVisited();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            opaque: true,
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SchoolOnboardingPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationProvider.notifier).loadUnreadCount();
      ref.read(chatRoomListProvider.notifier).load();
      ref.read(fcmServiceProvider).reRegisterToken();
    }
  }

  void _onScroll() {
    if (_selectedTab != _HomeTab.feed) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 360) {
      ref.read(schoolProvider.notifier).loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolProvider);
    final notifier = ref.read(schoolProvider.notifier);
    final isPenalized = ref.watch(
      activePenaltyProvider.select((s) => s.isPenalized),
    );
    final chatUnreadCount = ref
        .watch(chatRoomListProvider)
        .rooms
        .fold(0, (sum, room) => sum + room.unreadCount);

    ref.listen(schoolProvider, (previous, next) {
      if (!mounted) return;
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      floatingActionButton: isPenalized
          ? null
          : FloatingActionButton(
              onPressed: () => _openWriteFlow(state.boards),
              backgroundColor: const Color(0xFF229BF3),
              elevation: 6,
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _SchoolBottomBar(
        currentIndex: _bottomIndex,
        chatUnreadCount: chatUnreadCount,
        onNavTap: (index) {
          if (index == 1) {
            ref.read(chatRoomListProvider.notifier).load();
            context.push(AppRoutes.chat);
            return;
          }
          if (index == 2) {
            context.push(AppRoutes.meal);
            return;
          }
          if (index == 3) {
            context.push(AppRoutes.timetable);
            return;
          }
          if (index == 4) {
            context.push(AppRoutes.profile);
            return;
          }
          setState(() => _bottomIndex = index);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            SchoolHeader(
              schoolName: state.schoolName.isEmpty ? '학교 로딩 중...' : state.schoolName,
              onSearchTap: () => context.push(
                AppRoutes.search,
                extra: {
                  'keyword': '',
                  'scopeTitle': state.schoolName.isEmpty
                      ? '전체 피드'
                      : '${state.schoolName} 전체 피드',
                },
              ),
            ),
            const DDayStrip(),
            _HomeTabBar(
              selectedTab: _selectedTab,
              onChanged: (tab) {
                setState(() => _selectedTab = tab);
                if (tab == _HomeTab.feed && state.selectedBoardId != null) {
                  notifier.selectAllBoards();
                }
                if (tab == _HomeTab.popular) {
                  notifier.loadHotPosts();
                }
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (_selectedTab == _HomeTab.popular) {
                    await notifier.loadHotPosts();
                  } else {
                    await notifier.refreshPosts();
                  }
                },
                child: _buildTabBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(SchoolState state) {
    final notifier = ref.read(schoolProvider.notifier);
    final boardNames = {
      for (final board in state.boards) board.id: board.title,
    };

    if (state.isLoading && !state.hasLoadedOnce) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: const [PostListSkeleton(count: 5)],
      );
    }

    switch (_selectedTab) {
      case _HomeTab.feed:
        return _FeedList(
          controller: _scrollController,
          posts: state.posts,
          topRecommendedPosts: state.topRecommendedPosts,
          boardNames: boardNames,
          hasNext: state.hasNext,
          isLoadingMore: state.isLoadingMore,
          onPostTap: (postId) async {
            final refreshed = await context.push<bool>('/post/$postId');
            if (refreshed == true && mounted) {
              notifier.reloadCurrentBoard();
            }
          },
        );
      case _HomeTab.popular:
        return _PopularList(
          posts: state.hotPosts,
          boardNames: boardNames,
          filter: state.hotFilter,
          isLoading: state.isLoadingHot,
          onFilterChanged: notifier.changeHotFilter,
          onPostTap: (postId) async {
            final refreshed = await context.push<bool>('/post/$postId');
            if (refreshed == true && mounted) {
              notifier.loadHotPosts();
            }
          },
        );
      case _HomeTab.boards:
        return _BoardDirectory(
          boards: state.boards,
          onBoardTap: (board) async {
            await context.push(
              '/board/${board.id}',
              extra: {'boardId': board.id, 'boardTitle': board.title},
            );
            if (mounted) {
              notifier.selectAllBoards();
            }
          },
        );
    }
  }

  Future<void> _openWriteFlow(List<BoardModel> boards) async {
    final activeBoards = boards.where((b) => b.active).toList();
    if (activeBoards.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('글을 작성할 게시판이 없어요.')));
      return;
    }

    final createdPostId = await context.push<int>(
      '/write-post',
      extra: {'availableBoards': activeBoards},
    );

    if (!mounted || createdPostId == null) return;

    await ref.read(schoolProvider.notifier).refreshPosts();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('게시글이 등록되었어요.')));
  }
}

class _HomeTabBar extends StatelessWidget {
  final _HomeTab selectedTab;
  final ValueChanged<_HomeTab> onChanged;

  const _HomeTabBar({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                alignment: switch (selectedTab) {
                  _HomeTab.feed => Alignment.centerLeft,
                  _HomeTab.popular => Alignment.center,
                  _HomeTab.boards => Alignment.centerRight,
                },
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF229BF3),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2814A3F7),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _HomeTabButton(
                    label: '피드',
                    selected: selectedTab == _HomeTab.feed,
                    onTap: () => onChanged(_HomeTab.feed),
                  ),
                  _HomeTabButton(
                    label: '인기',
                    selected: selectedTab == _HomeTab.popular,
                    onTap: () => onChanged(_HomeTab.popular),
                  ),
                  _HomeTabButton(
                    label: '게시판',
                    selected: selectedTab == _HomeTab.boards,
                    onTap: () => onChanged(_HomeTab.boards),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HomeTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.05,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF8C8F95),
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  final ScrollController controller;
  final List<PostSummary> posts;
  final List<PostSummary> topRecommendedPosts;
  final Map<int, String> boardNames;
  final bool hasNext;
  final bool isLoadingMore;
  final ValueChanged<int> onPostTap;

  const _FeedList({
    required this.controller,
    required this.posts,
    required this.topRecommendedPosts,
    required this.boardNames,
    required this.hasNext,
    required this.isLoadingMore,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final hotIds = topRecommendedPosts.map((post) => post.id).toSet();
    final feedPosts = posts.where((post) => !hotIds.contains(post.id)).toList();

    if (posts.isEmpty && topRecommendedPosts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 68, 18, 20),
        children: const [_EmptyFeedState()],
      );
    }

    final totalPostCount = topRecommendedPosts.length + feedPosts.length;
    return ListView.separated(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      itemCount: totalPostCount + 1,
      separatorBuilder: (context, index) {
        if (index >= totalPostCount - 1) return const SizedBox.shrink();
        return const Divider(
          height: 1, thickness: 1, color: Color(0xFFD5DDE6),
          indent: 12, endIndent: 12,
        );
      },
      itemBuilder: (context, index) {
        if (index < topRecommendedPosts.length) {
          final post = topRecommendedPosts[index];
          return Container(
            color: const Color(0xFFF6FBFF),
            child: PostSummaryCard(
              post: post,
              compact: true,
              showDivider: false,
              categoryLabel: boardNames[post.boardId],
              hot: true,
              onTap: () => onPostTap(post.id),
            ),
          );
        }

        final feedIndex = index - topRecommendedPosts.length;
        if (feedIndex == feedPosts.length) {
          return _PagingFooter(hasNext: hasNext, isLoading: isLoadingMore);
        }

        final post = feedPosts[feedIndex];
        return Container(
          color: const Color(0xFFF6FBFF),
          child: PostSummaryCard(
            post: post,
            compact: true,
            showDivider: false,
            categoryLabel: boardNames[post.boardId],
            onTap: () => onPostTap(post.id),
          ),
        );
      },
    );
  }
}

class _PopularList extends StatelessWidget {
  final List<PostSummary> posts;
  final Map<int, String> boardNames;
  final HotFilter filter;
  final bool isLoading;
  final ValueChanged<HotFilter> onFilterChanged;
  final ValueChanged<int> onPostTap;

  const _PopularList({
    required this.posts,
    required this.boardNames,
    required this.filter,
    required this.isLoading,
    required this.onFilterChanged,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: _HotFilterRow(selected: filter, onChanged: onFilterChanged),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 64),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          )
        else if (posts.isEmpty)
          _EmptyPopularState(filter: filter)
        else
          for (int i = 0; i < posts.length; i++) ...[
            Container(
              color: const Color(0xFFF6FBFF),
              child: PostSummaryCard(
                post: posts[i],
                compact: true,
                showDivider: false,
                categoryLabel: boardNames[posts[i].boardId],
                onTap: () => onPostTap(posts[i].id),
              ),
            ),
            if (i < posts.length - 1)
              const Divider(
                height: 1, thickness: 1, color: Color(0xFFD5DDE6),
                indent: 12, endIndent: 12,
              ),
          ],
      ],
    );
  }
}

class _HotFilterRow extends StatelessWidget {
  final HotFilter selected;
  final ValueChanged<HotFilter> onChanged;

  const _HotFilterRow({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: HotFilter.values.map((filter) {
        final isSelected = selected == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => onChanged(filter),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFFE1ECF5),
                ),
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF6E7A86),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BoardDirectory extends StatelessWidget {
  final List<BoardModel> boards;
  final ValueChanged<BoardModel> onBoardTap;

  const _BoardDirectory({
    required this.boards,
    required this.onBoardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (boards.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 68, 18, 20),
        children: const [_EmptyBoardDirectoryState()],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      itemCount: boards.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final board = boards[index];
        return InkWell(
          onTap: () => onBoardTap(board),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1ECF5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tag_rounded,
                    color: Color(0xFF14A3F7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        board.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                        ),
                      ),
                      if (board.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          board.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7D8790),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA7B2),
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _PagingFooter extends StatelessWidget {
  final bool hasNext;
  final bool isLoading;

  const _PagingFooter({
    required this.hasNext,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          hasNext ? '스크롤하면 더 불러와요' : '마지막 게시글까지 확인했어요',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8D9AA6),
          ),
        ),
      ),
    );
  }
}
class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.forum_outlined,
      title: '아직 올라온 글이 없어요',
      message: '학교 친구들이 볼 수 있는 첫 글을 작성해보세요.',
    );
  }
}

class _EmptyPopularState extends StatelessWidget {
  final HotFilter filter;

  const _EmptyPopularState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.local_fire_department_outlined,
      title: '${filter.label} 인기글이 없어요',
      message: '좋아요와 댓글이 쌓이면 이곳에 모여요.',
      accentColor: const Color(0xFFFF6B35),
    );
  }
}

class _EmptyBoardDirectoryState extends StatelessWidget {
  const _EmptyBoardDirectoryState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.grid_view_rounded,
      title: '게시판이 아직 없어요',
      message: '관리자가 게시판을 만들면 이곳에 표시돼요.',
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accentColor;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.accentColor = const Color(0xFF14A3F7),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      child: Column(
        children: [
          Icon(icon, size: 40, color: accentColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7D8790),
            ),
          ),
        ],
      ),
    );
  }
}

void _showPenaltyDialog(BuildContext context, ActivePenaltyModel penalty) {
  final expiresAt = penalty.expiresAt;
  final reasonLabel = penalty.reasonLabel;

  String expiresStr = '';
  if (expiresAt != null) {
    expiresStr =
        '${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')} '
        '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.gavel_rounded, color: Color(0xFFE05C7B), size: 22),
          SizedBox(width: 8),
          Text(
            '이용 제한 안내',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '커뮤니티 규칙 위반으로 일부 기능이 제한되었어요.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF444444),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _DialogInfoRow(label: '사유', value: reasonLabel),
          if (expiresStr.isNotEmpty)
            _DialogInfoRow(label: '해제 예정', value: expiresStr),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '제한 기간에는 게시글, 댓글 작성과 채팅이 제한돼요. 게시글 열람은 가능해요.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFE05C7B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            '확인',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF14A3F7),
            ),
          ),
        ),
      ],
    ),
  );
}

void _showWarningDialog(BuildContext context, UnreadWarningModel warning) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _WarningDialog(warning: warning),
  );
}

class _WarningDialog extends ConsumerWidget {
  final UnreadWarningModel warning;

  const _WarningDialog({required this.warning});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuedStr =
        '${warning.issuedAt.year}.${warning.issuedAt.month.toString().padLeft(2, '0')}.${warning.issuedAt.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
          SizedBox(width: 8),
          Text(
            '관리자 경고',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '커뮤니티 규칙 위반으로 관리자 경고를 받았어요.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF444444),
              height: 1.5,
            ),
          ),
          if (warning.targetType != null && warning.targetSummary != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '신고된 ${warning.targetTypeLabel}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9AA7B2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning.targetSummary!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF444444),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Text(
              warning.adminComment,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF78350F),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '경고 일시: $issuedStr',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9AA7B2)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '경고 누적 시 이용이 제한될 수 있어요.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ref
                .read(unreadWarningProvider.notifier)
                .markRead(warning.warningId);
          },
          child: const Text(
            '확인했어요',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFFF59E0B),
            ),
          ),
        ),
      ],
    );
  }
}

class _SchoolBottomBar extends StatelessWidget {
  final int currentIndex;
  final int chatUnreadCount;
  final ValueChanged<int> onNavTap;

  const _SchoolBottomBar({
    required this.currentIndex,
    required this.chatUnreadCount,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8EEF3), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              icon: Icons.home_rounded,
              label: '홈',
              selected: currentIndex == 0,
              onTap: () => onNavTap(0),
            ),
            _BottomNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: '채팅',
              selected: currentIndex == 1,
              onTap: () => onNavTap(1),
              badgeCount: chatUnreadCount,
            ),
            _BottomNavItem(
              icon: Icons.restaurant_outlined,
              label: '급식',
              selected: currentIndex == 2,
              onTap: () => onNavTap(2),
            ),
            _BottomNavItem(
              icon: Icons.calendar_today_outlined,
              label: '시간표',
              selected: currentIndex == 3,
              onTap: () => onNavTap(3),
            ),
            _BottomNavItem(
              icon: Icons.person_outline_rounded,
              label: '내정보',
              selected: currentIndex == 4,
              onTap: () => onNavTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF229BF3) : const Color(0xFF282D33);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 27),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: color,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9AA7B2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
