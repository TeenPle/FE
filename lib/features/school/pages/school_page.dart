import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../features/auth/provider/login_provider.dart';
import '../../../features/chat/provider/chat_room_list_provider.dart';
import '../../../features/notification/provider/notification_provider.dart';
import '../../../features/notification/service/fcm_service.dart';
import '../../../core/widgets/post_summary_skeleton.dart';
import '../../../features/dday/widgets/dday_strip.dart';
import '../../../features/penalty/models/penalty_model.dart';
import '../../../features/penalty/provider/penalty_provider.dart';
import '../../../features/warning/models/warning_model.dart';
import '../../../features/warning/provider/warning_provider.dart';
import '../form/board_tab_bar.dart';
import '../models/board_model.dart';
import '../models/hot_filter.dart';
import '../models/post_summary.dart';
import '../provider/school_providers.dart';
import 'widgets/post_summary_card.dart';
import 'widgets/school_header.dart';

/// 학교 커뮤니티 메인 화면
class SchoolPage extends ConsumerStatefulWidget {
  const SchoolPage({super.key});

  @override
  ConsumerState<SchoolPage> createState() => _SchoolPageState();
}

class _SchoolPageState extends ConsumerState<SchoolPage>
    with WidgetsBindingObserver {
  static const int _previewCount = 4;

  int _bottomIndex = 0;
  bool _penaltyDialogShown = false;
  bool _warningDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      // async 갭 이전에 context 캡처
      final dialogContext = context;

      int? schoolId = ref.read(loginProvider).loginResponse?.schoolId;
      schoolId ??= await ref.read(tokenStorageProvider).getSchoolId();

      if (schoolId != null) {
        ref.read(schoolProvider.notifier).loadInitialSchool(schoolId);
      }

      // 제재 상태 + 미확인 경고 동시 로드
      await Future.wait([
        ref.read(activePenaltyProvider.notifier).load(),
        ref.read(unreadWarningProvider.notifier).load(),
      ]);

      if (!mounted || !dialogContext.mounted) return;

      // 제재 중이면 제재 다이얼로그 표시 (경고보다 우선)
      final penaltyState = ref.read(activePenaltyProvider);
      if (penaltyState.isPenalized && !_penaltyDialogShown) {
        _penaltyDialogShown = true;
        _showPenaltyDialog(dialogContext, penaltyState.penalty!);
        return; // 제재 다이얼로그가 있으면 경고는 다음 접속 시 표시
      }

      // 미확인 경고가 있으면 경고 다이얼로그 표시 (1회)
      final warningState = ref.read(unreadWarningProvider);
      if (warningState.hasUnread && !_warningDialogShown) {
        _warningDialogShown = true;
        _showWarningDialog(dialogContext, warningState.warning!);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fcm = ref.read(fcmServiceProvider);
      fcm.init().catchError((e) {
        if (kDebugMode) debugPrint('[FCM ERROR] $e');
      });
      // 앱이 종료 상태에서 알림 탭으로 실행된 경우 처리
      fcm.handleInitialMessage();
      ref.read(notificationProvider.notifier).loadUnreadCount();
      // 하단 채팅 버튼 위 미읽음 배지를 표시하기 위해 채팅방 목록의 unreadCount를 미리 가져온다.
      ref.read(chatRoomListProvider.notifier).load();
      // 앱이 켜져 있는 동안 채팅 목록/배지는 유저별 STOMP 이벤트로 즉시 갱신한다.
      ref.read(chatRoomListProvider.notifier).startRealtime();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 백그라운드에서 앱으로 복귀 시 배지 갱신 (토큰 재등록은 onTokenRefresh 리스너가 담당)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationProvider.notifier).loadUnreadCount();
      // 백그라운드에서 받은 채팅도 홈 복귀 시 배지에 반영한다.
      ref.read(chatRoomListProvider.notifier).load();
      ref.read(fcmServiceProvider).reRegisterToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolProvider);
    final notifier = ref.read(schoolProvider.notifier);
    // 채팅 버튼 배지는 모든 채팅방의 미읽음 메시지 수를 합산해서 표시한다.
    final chatUnreadCount = ref.watch(chatRoomListProvider).rooms
        .fold(0, (sum, room) => sum + room.unreadCount);

    final BoardModel? selectedBoard = state.boards.where(
          (board) => board.id == state.selectedBoardId,
    ).isEmpty
        ? null
        : state.boards.firstWhere(
          (board) => board.id == state.selectedBoardId,
    );

    final selectedBoardTitle = selectedBoard?.title ?? '게시판';

    /// 메인에서는 선택된 게시판의 일부 글만 미리보기로 노출
    final previewPosts = state.posts.take(_previewCount).toList();

    ref.listen(schoolProvider, (previous, next) {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final isPenalized = ref.watch(
      activePenaltyProvider.select((s) => s.isPenalized),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      floatingActionButton: isPenalized || state.selectedBoardId == null
          ? null
          : FloatingActionButton(
              /// 현재 선택된 게시판 기준으로 글쓰기 화면으로 이동
              onPressed: () async {
                final createdPostId = await context.push<int>(
                  '/write-post',
                  extra: {
                    'boardId': state.selectedBoardId!,
                    'boardTitle': selectedBoardTitle,
                  },
                );

                if (!mounted) return;

                /// 글 작성 후 메인 미리보기 목록을 다시 불러옴
                if (createdPostId != null) {
                  await notifier.reloadCurrentBoard();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새 게시글이 등록되었어요.')),
                  );
                }
              },
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF444444),
              shape: const CircleBorder(),
              child: const Icon(Icons.edit_rounded, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _bottomIndex,
        chatUnreadCount: chatUnreadCount,
        onTap: (index) {
          if (index == 1) {
            // 채팅 탭을 누르는 순간 최신 미읽음 수를 다시 동기화한다.
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
          setState(() {
            _bottomIndex = index;
          });
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            SchoolHeader(
              schoolName: state.schoolName.isEmpty ? '학교 로딩 중...' : state.schoolName,
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E6EA)),
            const DDayStrip(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E6EA)),
            BoardTabBar(
              boards: state.boards,
              selectedBoardId: state.selectedBoardId,

              /// 게시판 탭 선택 시 해당 게시판 미리보기 목록을 갱신
              onBoardSelected: (boardId) {
                notifier.selectBoard(boardId);
              },
            ),
            Expanded(
              child: state.isLoading && !state.hasLoadedOnce
                  ? ListView(
                      padding: EdgeInsets.zero,
                      children: const [PostListSkeleton(count: 4)],
                    )
                  : RefreshIndicator(
                /// 메인 미리보기 목록 새로고침
                onRefresh: notifier.refreshPosts,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 130),
                  children: [
                    if (previewPosts.isEmpty && !state.isLoading)
                      const _EmptyPreviewState(),

                    if (previewPosts.isNotEmpty)
                      _SectionCard(
                        child: Column(
                          children: [
                            for (int i = 0; i < previewPosts.length; i++)
                              PostSummaryCard(
                                post: previewPosts[i],
                                showDivider: i != previewPosts.length - 1,

                                /// 게시글 카드 클릭 시 게시글 상세 페이지로 이동
                                onTap: () async {
                                  final refreshed = await context.push<bool>('/post/${previewPosts[i].id}');
                                  if (refreshed == true && mounted) {
                                    notifier.reloadCurrentBoard();
                                  }
                                },
                              ),
                          ],
                        ),
                      ),

                    if (state.selectedBoardId != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            /// 더보기 클릭 시 게시판 상세 페이지로 이동
                            onPressed: () {
                              context.push(
                                '/board/${state.selectedBoardId!}',
                                extra: {
                                  'boardId': state.selectedBoardId!,
                                  'boardTitle': selectedBoardTitle,
                                },
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFFE2EAF0),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              '$selectedBoardTitle 더보기',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5C6975),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // HOT 섹션
                    _HotSection(
                      hotPosts: state.hotPosts,
                      hotFilter: state.hotFilter,
                      isLoading: state.isLoadingHot,
                      onFilterChanged: (f) =>
                          notifier.changeHotFilter(f),
                      onPostTap: (postId) async {
                        final refreshed = await context.push<bool>('/post/$postId');
                        if (refreshed == true && mounted) {
                          notifier.loadHotPosts();
                        }
                      },
                      onMoreTap: () =>
                          context.push(AppRoutes.hotBoard),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFFE05C7B), size: 22),
            SizedBox(width: 8),
            Text(
              '이용 제한 안내',
              style: TextStyle(
                fontSize: 17,
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
              '커뮤니티 규칙 위반으로 인해 일부 기능이 제한되었습니다.',
              style: TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
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
                '제재 기간 중에는 게시글·댓글 작성 및 채팅이 제한됩니다. 게시글 열람은 가능합니다.',
                style: TextStyle(
                  fontSize: 12,
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
                color: Color(0xFF5A8EA8),
              ),
            ),
          ),
        ],
      ),
    );
}

/// 경고 안내 다이얼로그 — 확인 시 BE에 읽음 처리 (1회만 표시)
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
              fontSize: 17,
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
            '커뮤니티 규칙 위반으로 관리자 경고를 받았습니다.',
            style: TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9AA7B2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning.targetSummary!,
                    style: const TextStyle(
                      fontSize: 13,
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
                fontSize: 14,
                color: Color(0xFF78350F),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '경고 일시: $issuedStr',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9AA7B2)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '경고 누적 시 이용이 제한될 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ref.read(unreadWarningProvider.notifier).markRead(warning.warningId);
          },
          child: const Text(
            '확인했습니다',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
          ),
        ),
      ],
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
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9AA7B2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
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

/// 메인에서 게시글 미리보기가 없을 때 보여주는 빈 상태
class _EmptyPreviewState extends StatelessWidget {
  const _EmptyPreviewState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 38,
            color: Color(0xFF9AA7B2),
          ),
          SizedBox(height: 12),
          Text(
            '아직 미리볼 게시글이 없어요.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '게시판에 첫 글을 작성해보세요.',
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

/// HOT 게시판 섹션 (메인 화면 하단)
class _HotSection extends StatelessWidget {
  final List<PostSummary> hotPosts;
  final HotFilter hotFilter;
  final bool isLoading;
  final ValueChanged<HotFilter> onFilterChanged;
  final ValueChanged<int> onPostTap;
  final VoidCallback onMoreTap;

  static const int _previewCount = 4;

  const _HotSection({
    required this.hotPosts,
    required this.hotFilter,
    required this.isLoading,
    required this.onFilterChanged,
    required this.onPostTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = hotPosts.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Row(
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 18),
              ),
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
              // 필터 칩
              ...HotFilter.values.map((f) {
                final selected = hotFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => onFilterChanged(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFFF3F6FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF9AA7B2),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // 게시글 카드
        if (isLoading)
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (hotPosts.isEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                '${hotFilter.label} HOT 게시글이 없어요.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9AA7B2),
                ),
              ),
            ),
          )
        else ...[
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                for (int i = 0; i < preview.length; i++)
                  PostSummaryCard(
                    post: preview[i],
                    showDivider: i != preview.length - 1,
                    onTap: () => onPostTap(preview[i].id),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: SizedBox(
              height: 46,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onMoreTap,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFFCDB5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '🔥 HOT 게시판 더보기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 게시글 미리보기 섹션을 감싸는 카드
class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}
