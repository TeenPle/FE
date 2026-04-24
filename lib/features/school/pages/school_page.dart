import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../features/auth/provider/login_provider.dart';
import '../../../features/notification/provider/notification_provider.dart';
import '../../../features/notification/service/fcm_service.dart';
import '../form/board_tab_bar.dart';
import '../models/board_model.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      int? schoolId = ref.read(loginProvider).loginResponse?.schoolId;
      schoolId ??= await ref.read(tokenStorageProvider).getSchoolId();

      if (schoolId != null) {
        ref.read(schoolProvider.notifier).loadInitialSchool(schoolId);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fcm = ref.read(fcmServiceProvider);
      fcm.init().catchError((e) {
        // ignore: avoid_print
        print('[FCM ERROR] $e');
      });
      // 앱이 종료 상태에서 알림 탭으로 실행된 경우 처리
      fcm.handleInitialMessage();
      ref.read(notificationProvider.notifier).loadUnreadCount();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 백그라운드에서 앱으로 복귀 시 배지 갱신
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationProvider.notifier).loadUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolProvider);
    final notifier = ref.read(schoolProvider.notifier);

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

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      floatingActionButton: FloatingActionButton(
        onPressed: state.selectedBoardId == null
            ? null

        /// 현재 선택된 게시판 기준으로 글쓰기 화면으로 이동
            : () async {
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
              const SnackBar(
                content: Text('새 게시글이 등록되었어요.'),
              ),
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
        onTap: (index) {
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
                  ? const Center(child: CircularProgressIndicator())
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
                                onTap: () {
                                  context.push('/post/${previewPosts[i].id}');
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