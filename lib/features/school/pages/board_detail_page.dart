import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../features/notification/provider/notification_provider.dart';
import '../../../features/penalty/provider/penalty_provider.dart';
import '../form/board_tab_bar.dart';
import '../models/post_sort_type.dart';
import '../provider/school_providers.dart';
import '../provider/school_state.dart';
import '../provider/school_provider.dart';
import 'widgets/post_summary_card.dart';

/// 특정 게시판의 전체 글 목록을 보여주는 상세 페이지
class BoardDetailPage extends ConsumerStatefulWidget {
  final int boardId;
  final String boardTitle;

  const BoardDetailPage({
    super.key,
    required this.boardId,
    required this.boardTitle,
  });

  @override
  ConsumerState<BoardDetailPage> createState() => _BoardDetailPageState();
}

class _BoardDetailPageState extends ConsumerState<BoardDetailPage> {
  @override
  void initState() {
    super.initState();

    /// 진입 시 현재 게시판을 선택 상태로 맞추고 목록을 불러옴
    Future.microtask(() {
      ref.read(schoolProvider.notifier).selectBoard(widget.boardId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolProvider);
    final notifier = ref.read(schoolProvider.notifier);

    // 현재 선택된 게시판 제목 (동적)
    final currentBoard = state.boards.where((b) => b.id == state.selectedBoardId).firstOrNull;
    final currentBoardTitle = currentBoard?.title ?? widget.boardTitle;

    ref.listen(schoolProvider, (previous, next) {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEFF4F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      /// 이전 화면으로 이동
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/school');
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF111111),
                        size: 22,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      currentBoardTitle,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => context.push(AppRoutes.profile),
                            icon: const Icon(
                              Icons.account_circle_outlined,
                              color: Color(0xFF111111),
                              size: 26,
                            ),
                          ),
                          _BoardNotificationButton(
                            onTap: () async {
                              await context.push(AppRoutes.notifications);
                              if (context.mounted) {
                                ref
                                    .read(notificationProvider.notifier)
                                    .loadUnreadCount();
                              }
                            },
                          ),
                          IconButton(
                            onPressed: () => context.push(AppRoutes.settings),
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Color(0xFF111111),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _WriteFab(
        state: state,
        notifier: notifier,
      ),
      body: Column(
        children: [
          BoardTabBar(
            boards: state.boards,
            selectedBoardId: state.selectedBoardId,
            onBoardSelected: (boardId) {
              notifier.selectBoard(boardId);
            },
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E6EA)),
          Container(
            width: double.infinity,
            color: const Color(0xFFEFF4F9),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                _SortDropdown(
                  selectedSortType: state.sortType,
                  onSortSelected: notifier.changeSortType,
                ),
                const Spacer(),
                _SearchPill(
                  onTap: () {
                    context.push(
                      '/search',
                      extra: {'keyword': ''},
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading && !state.hasLoadedOnce
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: notifier.refreshPosts,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                itemCount: state.posts.length +
                    (state.posts.isEmpty ? 1 : 0) +
                    (state.posts.isNotEmpty ? 1 : 0),
                separatorBuilder: (context, index) {
                  if (state.posts.isEmpty) return const SizedBox.shrink();
                  if (index < state.posts.length - 1) {
                    return const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFD5DDE6),
                      indent: 12,
                      endIndent: 12,
                    );
                  }
                  return const SizedBox.shrink();
                },
                itemBuilder: (context, index) {
                  if (state.posts.isEmpty) {
                    return const _EmptyBoardPostState();
                  }

                  if (index < state.posts.length) {
                    return Container(
                      color: const Color(0xFFEFF4F9),
                      child: PostSummaryCard(
                        post: state.posts[index],
                        compact: true,
                        showDivider: false,
                        onTap: () async {
                          final refreshed = await context.push<bool>(
                            '/post/${state.posts[index].id}',
                          );
                          if (refreshed == true) {
                            await notifier.reloadCurrentBoard();
                          }
                        },
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: _LoadMoreSection(
                      hasNext: state.hasNext,
                      isLoadingMore: state.isLoadingMore,
                      onLoadMore: notifier.loadMorePosts,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 게시판 상단바 알림 아이콘 (배지 포함)
class _BoardNotificationButton extends ConsumerWidget {
  final Future<void> Function() onTap;

  const _BoardNotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      notificationProvider.select((s) => s.unreadCount),
    );

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 26,
              color: Color(0xFF111111),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE05C7B),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 최신순 드롭다운 모양 위젯
class _SortDropdown extends StatelessWidget {
  final PostSortType selectedSortType;
  final ValueChanged<PostSortType> onSortSelected;

  const _SortDropdown({
    required this.selectedSortType,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PostSortType>(
      color: Colors.white,
      padding: EdgeInsets.zero,
      onSelected: onSortSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: PostSortType.latest, child: Text('최신순')),
        PopupMenuItem(value: PostSortType.popular, child: Text('인기순')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedSortType == PostSortType.latest ? '최신순' : '인기순',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B6B6B), size: 18),
        ],
      ),
    );
  }
}

/// 검색 pill 위젯
class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE1E1E1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, size: 17, color: Color(0xFF6A6A6A)),
            SizedBox(width: 4),
            Text(
              '검색',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A6A6A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 게시판에 글이 없을 때 보여주는 빈 상태
class _EmptyBoardPostState extends StatelessWidget {
  const _EmptyBoardPostState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 40, 18, 0),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 40, color: Color(0xFF9AA7B2)),
          SizedBox(height: 12),
          Text(
            '아직 게시글이 없어요.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '첫 게시글을 작성해서 이야기를 시작해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF7D8790),
            ),
          ),
        ],
      ),
    );
  }
}

/// 더보기 / 로딩 / 마지막 상태 영역
class _LoadMoreSection extends StatelessWidget {
  final bool hasNext;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const _LoadMoreSection({
    required this.hasNext,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }

    if (!hasNext) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            '마지막 게시글까지 확인했어요.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7D8790),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onLoadMore,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFD6DEE7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          '게시글 더보기',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF5C6975),
          ),
        ),
      ),
    );
  }
}

/// 제재 상태를 반영한 글쓰기 FAB
class _WriteFab extends ConsumerWidget {
  final SchoolState state;
  final SchoolNotifier notifier;

  const _WriteFab({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPenalized = ref.watch(
      activePenaltyProvider.select((s) => s.isPenalized),
    );

    if (isPenalized || state.selectedBoardId == null) return const SizedBox.shrink();

    final currentBoard = state.boards.where((b) => b.id == state.selectedBoardId).firstOrNull;
    final boardTitle = currentBoard?.title ?? '';

    return FloatingActionButton(
      onPressed: () async {
        final createdPostId = await context.push<int>(
          '/write-post',
          extra: {
            'boardId': state.selectedBoardId!,
            'boardTitle': boardTitle,
          },
        );

        if (!context.mounted) return;

        if (createdPostId != null) {
          await notifier.reloadCurrentBoard();

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새 게시글이 등록되었어요.')),
          );
        }
      },
      backgroundColor: const Color(0xFF12A8FF),
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
      child: const Icon(Icons.edit_rounded, size: 28),
    );
  }
}
