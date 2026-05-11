import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/tap_scale.dart';
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
import '../provider/school_providers.dart';
import '../provider/school_state.dart';
import 'widgets/post_summary_card.dart';
import 'widgets/school_header.dart';
import '../../post/provider/post_detail_providers.dart';

enum _HomeTab { feed, popular, boards }

const bool _showSchoolMainAdTestSlot = true;

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

  /// 홈 탭 재탭: 최상단까지 부드럽게 스크롤 후 새로고침
  Future<void> _scrollToTopAndRefresh() async {
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    if (_selectedTab == _HomeTab.popular) {
      await ref.read(schoolProvider.notifier).loadHotPosts();
    } else {
      await ref.read(schoolProvider.notifier).refreshPosts();
    }
  }

  Future<void> _onRefresh() async {
    if (_selectedTab == _HomeTab.popular) {
      await ref.read(schoolProvider.notifier).loadHotPosts();
    } else {
      await ref.read(schoolProvider.notifier).refreshPosts();
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      floatingActionButton: isPenalized
          ? null
          : FloatingActionButton(
              onPressed: () {
                AppHaptics.light();
                _openWriteFlow(state.boards);
              },
              backgroundColor: const Color(0xFF229BF3),
              elevation: 6,
              child: const Icon(Icons.edit_rounded,
                  color: Colors.white, size: 24),
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
          // 홈(index 0): 이미 홈이면 최상단으로 스크롤 후 새로고침
          if (_bottomIndex == 0) {
            _scrollToTopAndRefresh();
          }
          setState(() => _bottomIndex = 0);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단바는 항상 고정
            SchoolHeader(
              schoolName: state.schoolName.isEmpty
                  ? '학교 로딩 중...'
                  : state.schoolName,
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
            // D-Day, 탭바, 게시글 목록이 하나의 스크롤로 이어짐
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: AnimationLimiter(
                  key: ValueKey(
                    _selectedTab == _HomeTab.popular
                        ? 'popular_${state.isLoadingHot}'
                        : _selectedTab.index,
                  ),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: DDayStrip()),
                      SliverToBoxAdapter(
                        child: _HomeTabBar(
                          selectedTab: _selectedTab,
                          onChanged: (tab) {
                            setState(() {
                              _selectedTab = tab;
                              // 탭 전환 시 스크롤 위치 초기화
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0);
                              }
                            });
                            if (tab == _HomeTab.feed &&
                                state.selectedBoardId != null) {
                              notifier.selectAllBoards();
                            }
                            if (tab == _HomeTab.popular) {
                              notifier.loadHotPosts();
                            }
                          },
                        ),
                      ),
                      ..._buildTabSlivers(state),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 현재 탭에 맞는 슬리버 목록 반환
  List<Widget> _buildTabSlivers(SchoolState state) {
    if (state.isLoading && !state.hasLoadedOnce) {
      return [
        const SliverToBoxAdapter(
          child: PostListSkeleton(count: 5),
        ),
      ];
    }

    switch (_selectedTab) {
      case _HomeTab.feed:
        return _buildFeedSlivers(state);
      case _HomeTab.popular:
        return _buildPopularSlivers(state);
      case _HomeTab.boards:
        return _buildBoardSlivers(state);
    }
  }

  List<Widget> _buildFeedSlivers(SchoolState state) {
    final notifier = ref.read(schoolProvider.notifier);
    final boardNames = {
      for (final board in state.boards) board.id: board.title,
    };
    final hotIds =
        state.topRecommendedPosts.map((post) => post.id).toSet();
    final feedPosts =
        state.posts.where((post) => !hotIds.contains(post.id)).toList();

    if (state.posts.isEmpty && state.topRecommendedPosts.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 68, 18, 20),
            child: _EmptyFeedState(),
          ),
        ),
      ];
    }

    final showAdSlot = _showSchoolMainAdTestSlot;
    final adInsertIndex = state.topRecommendedPosts.isNotEmpty ? 1 : 0;
    final totalPostCount =
        state.topRecommendedPosts.length + feedPosts.length;
    final totalItemCount =
        totalPostCount + (showAdSlot ? 1 : 0) + 1; // +1 for footer

    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 16),
        sliver: SliverList.separated(
          itemCount: totalItemCount,
          separatorBuilder: (context, index) {
            if (index >= totalItemCount - 2) return const SizedBox.shrink();
            return Divider(
              height: 1,
              thickness: 1,
              color: context.colors.divider,
              indent: 12,
              endIndent: 12,
            );
          },
          itemBuilder: (context, index) {
            Widget item;
            if (index == totalItemCount - 1) {
              item = _PagingFooter(
                hasNext: state.hasNext,
                isLoading: state.isLoadingMore,
              );
            } else if (showAdSlot && index == adInsertIndex) {
              item = const _SchoolMainAdCard();
            } else {
              final postIndex =
                  showAdSlot && index > adInsertIndex ? index - 1 : index;

              if (postIndex < state.topRecommendedPosts.length) {
                final post = state.topRecommendedPosts[postIndex];
                item = Container(
                  color: context.colors.pageBg,
                  child: PostSummaryCard(
                    post: post,
                    compact: true,
                    showDivider: false,
                    categoryLabel: boardNames[post.boardId],
                    hot: true,
                    onTap: () async {
                      final postId = post.id;
                      final refreshed = await context.push<bool>('/post/$postId');
                      final detailState = ref.read(postDetailProvider(postId));
                      notifier.updatePostCommentCount(postId, detailState.comments.length);
                      if (refreshed == true && mounted) {
                        notifier.reloadCurrentBoard();
                      }
                    },
                  ),
                );
              } else {
                final feedIndex =
                    postIndex - state.topRecommendedPosts.length;
                final post = feedPosts[feedIndex];
                item = Container(
                  color: context.colors.pageBg,
                  child: PostSummaryCard(
                    post: post,
                    compact: true,
                    showDivider: false,
                    categoryLabel: boardNames[post.boardId],
                    onTap: () async {
                      final postId = post.id;
                      final refreshed = await context.push<bool>('/post/$postId');
                      final detailState = ref.read(postDetailProvider(postId));
                      notifier.updatePostCommentCount(postId, detailState.comments.length);
                      if (refreshed == true && mounted) {
                        notifier.reloadCurrentBoard();
                      }
                    },
                  ),
                );
              }
            }
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 380),
              child: SlideAnimation(
                verticalOffset: 30,
                child: FadeInAnimation(child: item),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildPopularSlivers(SchoolState state) {
    final notifier = ref.read(schoolProvider.notifier);
    final boardNames = {
      for (final board in state.boards) board.id: board.title,
    };

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: _HotFilterRow(
            selected: state.hotFilter,
            onChanged: notifier.changeHotFilter,
          ),
        ),
      ),
      if (state.isLoadingHot)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 64),
            child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.4)),
          ),
        )
      else if (state.hotPosts.isEmpty)
        SliverToBoxAdapter(
            child: _EmptyPopularState(filter: state.hotFilter))
      else
        SliverList.separated(
          itemCount: state.hotPosts.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: context.colors.divider,
            indent: 12,
            endIndent: 12,
          ),
          itemBuilder: (context, index) {
            final post = state.hotPosts[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 380),
              child: SlideAnimation(
                verticalOffset: 30,
                child: FadeInAnimation(
                  child: Container(
                    color: context.colors.pageBg,
                    child: PostSummaryCard(
                      post: post,
                      compact: true,
                      showDivider: false,
                      categoryLabel: boardNames[post.boardId],
                      onTap: () async {
                        final postId = post.id;
                        final refreshed = await context.push<bool>('/post/$postId');
                        final detailState = ref.read(postDetailProvider(postId));
                        notifier.updatePostCommentCount(postId, detailState.comments.length);
                        if (refreshed == true && mounted) {
                          notifier.loadHotPosts();
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  List<Widget> _buildBoardSlivers(SchoolState state) {
    final notifier = ref.read(schoolProvider.notifier);

    if (state.boards.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 68, 18, 20),
            child: _EmptyBoardDirectoryState(),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
        sliver: SliverList.separated(
          itemCount: state.boards.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final board = state.boards[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 380),
              child: SlideAnimation(
                verticalOffset: 30,
                child: FadeInAnimation(
                  child: TapScale(
                    scale: 0.97,
                    child: InkWell(
                      onTap: () async {
                        AppHaptics.selection();
                        await context.push(
                          '/board/${board.id}',
                          extra: {
                            'boardId': board.id,
                            'boardTitle': board.title,
                          },
                        );
                        if (mounted) {
                          notifier.selectAllBoards();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Builder(
                        builder: (context) {
                          final c = context.colors;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: c.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: c.tintBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.tag_rounded,
                                      color: Color(0xFF14A3F7), size: 22),
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
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      if (board.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          board.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: c.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded,
                                    color: c.iconSecondary, size: 24),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Future<void> _openWriteFlow(List<BoardModel> boards) async {
    final activeBoards = boards.where((b) => b.active).toList();
    if (activeBoards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('글을 작성할 게시판이 없어요.')));
      return;
    }

    final createdPostId = await context.push<int>(
      '/write-post',
      extra: {'availableBoards': activeBoards},
    );

    if (!mounted || createdPostId == null) return;

    await ref.read(schoolProvider.notifier).refreshPosts();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('게시글이 등록되었어요.')));
  }
}

// ─── 탭바 ─────────────────────────────────────────────────

class _HomeTabBar extends StatelessWidget {
  final _HomeTab selectedTab;
  final ValueChanged<_HomeTab> onChanged;

  const _HomeTabBar({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.pageBg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          height: 40,
          width: 236,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: c.chipContainerBg,
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
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.05,
              fontWeight:
                  selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? Colors.white
                  : context.colors.textTertiary,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 인기 필터 ───────────────────────────────────────────

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
            onTap: () {
              AppHaptics.selection();
              onChanged(filter);
            },
            borderRadius: BorderRadius.circular(999),
            child: Builder(builder: (context) {
              final c = context.colors;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF6B35) : c.cardBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF6B35) : c.border,
                  ),
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : c.textMuted,
                  ),
                ),
              );
            }),
          ),
        );
      }).toList(),
    );
  }
}

// ─── 광고 카드 ───────────────────────────────────────────

class _SchoolMainAdCard extends StatelessWidget {
  const _SchoolMainAdCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.pageBg,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Material(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: Color(0xFF12A66A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4DF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'AD',
                              style: TextStyle(
                                fontSize: 9,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB26A00),
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '학교생활 제휴 안내',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: c.textMuted,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '우리 학교 근처 스터디 혜택 모아보기',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '청소년 이용 가능 제휴만 검수해서 보여주는 테스트 광고 영역입니다.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFF9AA7B2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 페이징 푸터 ─────────────────────────────────────────

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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.colors.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ─── 빈 상태 ─────────────────────────────────────────────

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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      child: Column(
        children: [
          Icon(icon, size: 40, color: accentColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 다이얼로그 ──────────────────────────────────────────

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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: Color(0xFFE05C7B), size: 22),
          const SizedBox(width: 8),
          Text(
            '이용 제한 안내',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
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
                fontSize: 12, color: Color(0xFF444444), height: 1.5),
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
                  fontSize: 11, color: Color(0xFFE05C7B), height: 1.5),
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
                fontWeight: FontWeight.w700, color: Color(0xFF14A3F7)),
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 8),
          Text(
            '관리자 경고',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
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
                fontSize: 12, color: Color(0xFF444444), height: 1.5),
          ),
          if (warning.targetType != null &&
              warning.targetSummary != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
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
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '경고 일시: $issuedStr',
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF9AA7B2)),
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
                  height: 1.4),
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
                color: Color(0xFFF59E0B)),
          ),
        ),
      ],
    );
  }
}

// ─── 하단 네비게이션바 ────────────────────────────────────

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
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.cardBg,
          border: Border(top: BorderSide(color: c.border, width: 1)),
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
    final color =
        selected ? const Color(0xFF229BF3) : context.colors.textMuted;

    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: TapScale(
        scale: 0.88,
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
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
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
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w500,
                color: color,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ─── 다이얼로그 정보 행 ───────────────────────────────────

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: c.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: c.textBody,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
