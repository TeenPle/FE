import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/active_page_provider.dart';
import '../form/comment_input_bar.dart';
import '../models/comment_model.dart';
import '../models/post_detail.dart';
import '../provider/post_detail_providers.dart';
import '../provider/post_detail_state.dart';
import '../../chat/provider/chat_room_list_provider.dart';
import '../../penalty/provider/penalty_provider.dart';
import '../../profile/provider/block_provider.dart';
import 'widgets/comment_item.dart';
import 'widgets/post_action_bar.dart';
import 'widgets/post_content_card.dart';
import 'widgets/poll_card.dart';
import 'write_post_page.dart';
import '../../../core/theme/app_colors.dart';

/// 게시글 상세 페이지
class PostDetailPage extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _commentKeys = {};
  late final StateController<ActivePage> _activePageController;
  late final int _postId;
  int? _pendingFocusParentId;
  Set<int> _commentIdsBeforeSubmit = const {};

  @override
  void initState() {
    super.initState();
    _postId = widget.postId;
    _activePageController = ref.read(activePageProvider.notifier);

    debugPrint('PostDetailPage 진입 postId = $_postId');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 이 게시글을 보고 있음을 알림 억제 로직에 알린다.
      _activePageController.state = ActivePage(
        postId: _postId,
      );
      ref.read(postDetailProvider(_postId).notifier).loadPostDetail();
    });
  }

  @override
  void dispose() {
    Future(() {
      if (_activePageController.state.postId == _postId) {
        _activePageController.state = const ActivePage();
      }
    });
    _scrollController.dispose();
    super.dispose();
  }

  void _handleCommentSubmit(PostDetailState state, String content) {
    _pendingFocusParentId = state.replyingToCommentId;
    _commentIdsBeforeSubmit = state.comments.map((e) => e.commentId).toSet();
    ref.read(postDetailProvider(widget.postId).notifier).submitComment(content);
  }

  void _focusSubmittedComment(PostDetailState state) {
    final parentId = _pendingFocusParentId;
    final newComments = state.comments
        .where(
          (comment) => !_commentIdsBeforeSubmit.contains(comment.commentId),
        )
        .toList();
    _pendingFocusParentId = null;
    _commentIdsBeforeSubmit = const {};

    if (newComments.isEmpty) {
      _scrollToCommentsEnd();
      return;
    }

    final target = _pickFocusTarget(newComments, parentId);
    final targetKey = _commentKeys[target.commentId];
    if (targetKey?.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.28,
      );
      return;
    }

    if (parentId != null) {
      final parentKey = _commentKeys[parentId];
      if (parentKey?.currentContext != null) {
        Scrollable.ensureVisible(
          parentKey!.currentContext!,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: 0.28,
        );
        return;
      }
    }

    _scrollToCommentsEnd();
  }

  CommentModel _pickFocusTarget(List<CommentModel> comments, int? parentId) {
    final candidates = parentId == null
        ? comments.where((comment) => comment.parentId == null)
        : comments.where((comment) => comment.parentId == parentId);
    final pool = candidates.isEmpty ? comments : candidates;
    return pool.reduce((a, b) => a.commentId > b.commentId ? a : b);
  }

  void _scrollToCommentsEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailProvider(widget.postId));
    final notifier = ref.read(postDetailProvider(widget.postId).notifier);
    final post = state.post;
    final c = context.colors;

    ref.listen(postDetailProvider(widget.postId), (previous, next) async {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        notifier.clearMessages();
      }

      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!)));
        if (next.successMessage == '댓글이 등록되었습니다.') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _focusSubmittedComment(next);
          });
        }
        notifier.clearMessages();
      }

      /// 게시글 삭제 후 이전 화면으로 이동
      if (next.shouldClosePage &&
          next.shouldClosePage != previous?.shouldClosePage) {
        notifier.clearClosePageFlag();
        if (mounted) context.pop(true);
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: c.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        title: Text(
          '게시글',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            color: c.popupBg,
            icon: Icon(Icons.more_horiz, color: c.iconPrimary),
            onSelected: (value) async {
              if (value == 'edit' && post != null) {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => WritePostPage(
                      boardId: 0,
                      boardTitle: '게시글 수정',
                      isEditMode: true,
                      postId: post.postId,
                      initialTitle: post.title,
                      initialContent: post.content,
                      initialAnonymous: post.anonymous,
                      initialMediaList: post.mediaList,
                      initialPollOptions: post.poll?.options
                          .map((e) => e.text)
                          .toList(),
                    ),
                  ),
                );

                if (updated == true) {
                  await notifier.loadPostDetail();
                }
              } else if (value == 'delete') {
                final confirmed = await _showDeleteConfirmDialog(
                  context,
                  title: '게시글을 삭제할까요?',
                  description: '삭제한 게시글은 되돌릴 수 없습니다.',
                );

                if (confirmed == true) {
                  await notifier.deletePost();
                }
              } else if (value == 'chat') {
                if (post == null) return;
                if (post.isMine) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('자신의 게시글에는 채팅할 수 없습니다.')),
                  );
                } else if (post.authorDeleted ||
                    !post.canChatWithAuthor ||
                    post.authorId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('채팅을 시작할 수 없습니다.')),
                  );
                } else {
                  await _startChat(
                    context: context,
                    ref: ref,
                    otherUserId: post.authorId!,
                    post: post,
                  );
                }
              } else if (value == 'report' &&
                  post != null &&
                  post.canReportAuthor) {
                final report = await _showReportSheet(context);
                if (report != null) {
                  await notifier.reportPost(report.reason);
                }
              } else if (value == 'block' &&
                  post != null &&
                  post.canBlockAuthor &&
                  post.authorUserId != null) {
                final confirmed = await _showBlockConfirmDialog(context);
                if (confirmed == true && context.mounted) {
                  try {
                    await ref
                        .read(blockActionProvider)
                        .block(post.authorUserId!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('해당 사용자를 차단했습니다.')),
                      );
                      context.pop(true);
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('차단 처리에 실패했습니다.')),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              if (post != null && post.isMine) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: _CompactMenuText('수정하기'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: _CompactMenuText('삭제하기'),
                ),
              ],
              if (post == null || !post.isMine) ...[
                if (post != null && post.canChatWithAuthor)
                  const PopupMenuItem(
                    value: 'chat',
                    child: _CompactMenuText('채팅'),
                  ),
                if (post != null && post.canReportAuthor)
                  const PopupMenuItem(
                    value: 'report',
                    child: _CompactMenuText('신고하기'),
                  ),
                if (post != null &&
                    post.canBlockAuthor &&
                    post.authorUserId != null)
                  const PopupMenuItem(
                    value: 'block',
                    child: _CompactMenuText('차단하기', color: Color(0xFFE05C5C)),
                  ),
              ],
            ],
          ),
        ],
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Builder(
          builder: (context) {
            final isPenalized = ref.watch(
              activePenaltyProvider.select((s) => s.isPenalized),
            );
            if (isPenalized) return const SizedBox.shrink();
            return CommentInputBar(
              anonymous: state.commentAnonymous,
              isSubmitting: state.isSubmittingComment,
              replyingToCommentId: state.replyingToCommentId,
              onAnonymousChanged: notifier.toggleCommentAnonymous,
              onSubmit: (content) => _handleCommentSubmit(state, content),
              onCancelReply: notifier.cancelReply,
            );
          },
        ),
      ),
      body: state.isLoading && post == null
          ? const Center(child: CircularProgressIndicator())
          : post == null
          ? Center(
              child: Text(
                state.errorMessage ?? '게시글을 불러오지 못했습니다.',
                style: TextStyle(color: c.textBody),
              ),
            )
          : RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PostContentCard(post: post),
                  ),
                  if (post.poll != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PollCard(
                        poll: post.poll!,
                        isSubmitting: state.isSubmittingReaction,
                        onVote: notifier.votePoll,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PostActionBar(
                      likeCount: post.likeCount,
                      commentCount: state.comments.length,
                      likedByMe: state.likedByMe,
                      bookmarkedByMe: state.bookmarkedByMe,
                      onBookmarkTap: () => notifier.toggleBookmark(),
                      onLikeTap: () => notifier.toggleLike(),
                      onShareTap: () {
                        debugPrint('share post: ${post.postId}');
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 8, color: c.dividerBlue),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _CommentSectionHeader(
                      commentCount: state.comments.length,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: _buildCommentWidgets(
                        comments: state.comments,
                        replyingToCommentId: state.replyingToCommentId,
                        onReplyTap: (commentId, isReply) {
                          notifier.startReply(commentId, isReply: isReply);
                        },
                        onCommentLikeTap: (commentId) =>
                            notifier.likeComment(commentId),
                        likedCommentIds: state.likedCommentIds,
                        onCommentChatTap: (comment) async {
                          if (comment.isMine) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('자신의 댓글에는 채팅할 수 없습니다.'),
                              ),
                            );
                            return;
                          }
                          if (!comment.canChatWithAuthor ||
                              comment.authorUserId == null) {
                            return;
                          }
                          await _startChat(
                            context: context,
                            ref: ref,
                            otherUserId: comment.authorUserId!,
                            post: post,
                          );
                        },
                        onCommentReportTap: (commentId) {
                          _showReportSheet(context).then((report) {
                            if (report == null) return;
                            notifier.reportComment(commentId, report.reason);
                          });
                        },
                        onCommentEditTap: (comment) {
                          _showEditCommentDialog(
                            context,
                            initialContent: comment.content,
                            initialAnonymous: comment.anonymous,
                            onSubmit: (content, anonymous) {
                              notifier.updateComment(
                                commentId: comment.commentId,
                                content: content,
                                anonymous: anonymous,
                              );
                            },
                          );
                        },
                        onCommentDeleteTap: (commentId) async {
                          final confirmed = await _showDeleteConfirmDialog(
                            context,
                            title: '댓글을 삭제할까요?',
                            description: '삭제한 댓글은 되돌릴 수 없습니다.',
                          );

                          if (confirmed == true) {
                            await notifier.deleteComment(commentId);
                          }
                        },
                        onCommentBlockTap: (authorUserId) async {
                          final confirmed = await _showBlockConfirmDialog(
                            context,
                          );
                          if (confirmed == true && context.mounted) {
                            try {
                              await ref
                                  .read(blockActionProvider)
                                  .block(authorUserId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('해당 사용자를 차단했습니다.'),
                                  ),
                                );
                                await notifier.loadPostDetail();
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('차단 처리에 실패했습니다.'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 부모 댓글과 대댓글을 묶어서 화면에 구성
  List<Widget> _buildCommentWidgets({
    required List<CommentModel> comments,
    required int? replyingToCommentId,
    required void Function(int commentId, bool isReply) onReplyTap,
    required void Function(int commentId) onCommentLikeTap,
    required void Function(CommentModel comment) onCommentChatTap,
    required void Function(int commentId) onCommentReportTap,
    required void Function(CommentModel comment) onCommentEditTap,
    required void Function(int commentId) onCommentDeleteTap,
    required Set<int> likedCommentIds,
    required void Function(int authorUserId) onCommentBlockTap,
  }) {
    final parents = comments.where((e) => e.parentId == null).toList();

    if (parents.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              '아직 댓글이 없어요.\n첫 댓글을 남겨보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF7D8790),
              ),
            ),
          ),
        ),
      ];
    }

    return parents.asMap().entries.map((entry) {
      final index = entry.key;
      final parent = entry.value;
      final replies = comments
          .where((e) => e.parentId == parent.commentId)
          .toList();

      return Column(
        children: [
          CommentItem(
            key: _commentKeys.putIfAbsent(parent.commentId, () => GlobalKey()),
            comment: parent,
            replies: replies,
            likedByMe: likedCommentIds.contains(parent.commentId),
            isReplyTarget: replyingToCommentId == parent.commentId,
            onReplyTap: () => onReplyTap(parent.commentId, false),
            onLikeTap: () => onCommentLikeTap(parent.commentId),
            onChatTap: onCommentChatTap,
            onReportTap: onCommentReportTap,
            onEditTap: onCommentEditTap,
            onDeleteTap: onCommentDeleteTap,
            onBlockTap: onCommentBlockTap,
          ),
          if (index != parents.length - 1)
            Divider(height: 1, thickness: 1, color: context.colors.dividerBlue),
        ],
      );
    }).toList();
  }

  // 채팅방 생성/조회 후 이동
  Future<void> _startChat({
    required BuildContext context,
    required WidgetRef ref,
    required int otherUserId,
    required PostDetail post,
  }) async {
    try {
      final api = ref.read(chatApiProvider);
      final result = await api.createOrGetDm(
        otherUserId: otherUserId,
        sourcePostId: post.postId,
        roomTitle: post.title,
      );

      // 채팅방 목록 갱신
      ref.read(chatRoomListProvider.notifier).load();

      if (context.mounted) {
        context.push(
          '/chat/rooms/${result['roomId']}',
          extra: {
            'otherUserId': result['otherUserId'],
            'displayName': result['displayName'] as String? ?? post.title,
            'blocked': result['blocked'] as bool? ?? false,
            'blockedByMe': result['blockedByMe'] as bool? ?? false,
            'blockedByOther': result['blockedByOther'] as bool? ?? false,
            'otherUserDeleted': result['otherUserDeleted'] as bool? ?? false,
            'canSendMessage': result['canSendMessage'] as bool? ?? true,
            'canReport': result['canReport'] as bool? ?? true,
            'canBlock': result['canBlock'] as bool? ?? true,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('채팅을 시작할 수 없습니다: $e')));
      }
    }
  }
}

/// 댓글 섹션 헤더
class _CommentSectionHeader extends StatelessWidget {
  final int commentCount;

  const _CommentSectionHeader({required this.commentCount});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Text(
          '댓글',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$commentCount',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14A3F7),
          ),
        ),
      ],
    );
  }
}

class _CompactMenuText extends StatelessWidget {
  final String text;
  final Color? color;

  const _CompactMenuText(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color ?? context.colors.textPrimary,
      ),
    );
  }
}

/// 차단 확인 다이얼로그
Future<bool?> _showBlockConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('사용자 차단'),
      content: const Text('이 사용자를 차단하면 해당 사용자의 게시글과 댓글이 보이지 않습니다.\n차단하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('차단하기', style: TextStyle(color: Color(0xFFE05C5C))),
        ),
      ],
    ),
  );
}

/// 신고 카테고리 선택 바텀시트
Future<_ReportSubmission?> _showReportSheet(BuildContext context) {
  String selectedReason = 'SPAM';
  return showModalBottomSheet<_ReportSubmission>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      const reasons = [
        ('SPAM', '광고·도배'),
        ('ABUSE', '욕설·비방'),
        ('HARASSMENT', '괴롭힘·위협'),
        ('OBSCENE', '성적·음란 콘텐츠'),
        ('ILLEGAL', '불법·위험 행위'),
        ('ETC', '기타 운영정책 위반'),
      ];

      return StatefulBuilder(
        builder: (context, setModalState) {
          final media = MediaQuery.of(context);
          final bottomInset = media.viewInsets.bottom;
          final maxHeight = (media.size.height - bottomInset) * 0.9;
          final c = context.colors;
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: c.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.tintBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.flag_outlined,
                              size: 20,
                              color: Color(0xFF426C82),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '신고하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '신고 카테고리를 선택해주세요.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: reasons.map((reason) {
                          final selected = selectedReason == reason.$1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ReportReasonTile(
                              label: reason.$2,
                              selected: selected,
                              onTap: () => setModalState(() {
                                selectedReason = reason.$1;
                              }),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            Navigator.pop(
                              context,
                              _ReportSubmission(reason: selectedReason),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14A3F7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '신고 접수',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _ReportSubmission {
  final String reason;

  const _ReportSubmission({required this.reason});
}

class _ReportReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReportReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = const Color(0xFF14A3F7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? c.tintBg : c.subtleBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c.borderBlue : c.border),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 19,
                color: selected ? accent : c.iconSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? c.textPrimary : c.textBody,
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

/// 삭제 확인 다이얼로그
Future<bool?> _showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String description,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      );
    },
  );
}

/// 댓글 수정 다이얼로그
Future<void> _showEditCommentDialog(
  BuildContext context, {
  required String initialContent,
  required bool initialAnonymous,
  required void Function(String content, bool anonymous) onSubmit,
}) {
  final controller = TextEditingController(text: initialContent);
  bool anonymous = initialAnonymous;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('댓글 수정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: '댓글 내용을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: anonymous,
                      onChanged: (value) {
                        setLocalState(() {
                          anonymous = value ?? true;
                        });
                      },
                    ),
                    const Text('익명으로 수정'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  final content = controller.text.trim();
                  if (content.isEmpty) return;

                  Navigator.pop(dialogContext);
                  onSubmit(content, anonymous);
                },
                child: const Text('수정'),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(controller.dispose);
}
