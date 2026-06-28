import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/active_page_provider.dart';
import '../../../core/config/feature_flags.dart';
import '../form/comment_input_bar.dart';
import '../models/comment_model.dart';
import '../models/post_detail.dart';
import '../provider/post_detail_provider.dart';
import '../provider/post_detail_providers.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../chat/provider/chat_room_list_provider.dart';
import '../../penalty/provider/penalty_provider.dart';
import '../../profile/provider/block_provider.dart';
import 'widgets/comment_item.dart';
import 'widgets/post_action_bar.dart';
import 'widgets/post_content_card.dart';
import 'widgets/poll_card.dart';
import 'write_post_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/school_main_ad_card.dart';

/// 게시글 상세 페이지
class PostDetailPage extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  late final PostDetailNotifier _detailNotifier;
  late final StateController<ActivePage> _activePageNotifier;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _commentKeys = {};

  @override
  void initState() {
    super.initState();
    _detailNotifier = ref.read(postDetailProvider(widget.postId).notifier);
    _activePageNotifier = ref.read(activePageProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 이 게시글을 보고 있음을 알림 억제 로직에 알린다.
      _activePageNotifier.state = ActivePage(postId: widget.postId);
      _detailNotifier.loadPostDetail();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Future<void>(() {
      if (_detailNotifier.mounted) {
        _detailNotifier.cancelReply();
      }
      if (_activePageNotifier.mounted &&
          _activePageNotifier.state.postId == widget.postId) {
        _activePageNotifier.state = const ActivePage();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailProvider(widget.postId));
    final notifier = ref.read(postDetailProvider(widget.postId).notifier);
    final post = state.post;
    final c = context.colors;
    final isPenalized = ref.watch(
      activePenaltyProvider.select((s) => s.isPenalized),
    );

    ref.listen(postDetailProvider(widget.postId), (previous, next) async {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        showAppSnackBar(next.errorMessage!);
        notifier.clearMessages();
      }

      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        showAppSnackBar(next.successMessage!);
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
      backgroundColor: c.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        title: Text(
          '게시글',
          style: AppTextStyles.titleLarge.copyWith(color: c.textPrimary),
        ),
        actions: [
          PopupMenuButton<String>(
            color: c.popupBg,
            icon: Icon(Icons.more_horiz, color: c.iconPrimary),
            onSelected: (value) async {
              if (value == 'edit' && post != null) {
                if (isPenalized) {
                  showAppSnackBar('제재 중에는 게시글을 수정할 수 없어요.');
                  return;
                }

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
                  showAppSnackBar('게시글을 수정했어요.');
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
                if (isPenalized) {
                  showAppSnackBar('제재 중에는 채팅을 시작할 수 없어요.');
                  return;
                }
                if (post.isMine) {
                  showAppSnackBar('자신의 게시글에는 채팅할 수 없어요.');
                } else if (post.authorDeleted ||
                    !post.canChatWithAuthor ||
                    post.authorId == null) {
                  showAppSnackBar('채팅을 시작할 수 없어요.');
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
                _showReportSheet(
                  context,
                  onSubmit: (reason) {
                    notifier.reportPost(reason);
                  },
                );
              } else if (value == 'block' &&
                  post != null &&
                  post.canBlockAuthor &&
                  post.authorUserId != null) {
                final router = GoRouter.of(context);
                final confirmed = await _showBlockConfirmDialog(context);
                if (confirmed == true && mounted) {
                  try {
                    await ref
                        .read(blockActionProvider)
                        .block(post.authorUserId!);
                    if (mounted) {
                      showAppSnackBar('해당 사용자를 차단했어요.');
                      router.pop(true);
                    }
                  } catch (_) {
                    if (mounted) {
                      showAppSnackBar(
                        '차단 처리에 실패했어요.',
                        backgroundColor: const Color(0xFFE05C7B),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              if (post != null && post.isMine) ...[
                PopupMenuItem(
                  value: 'edit',
                  enabled: !isPenalized,
                  child: _CompactMenuText(
                    '수정하기',
                    color: isPenalized ? c.textTertiary : null,
                  ),
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
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: state.isLoading && post == null
                ? const Center(child: CircularProgressIndicator())
                : post == null
                ? Center(
                    child: Text(
                      state.errorMessage ?? '게시글을 불러오지 못했어요.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.textBody,
                      ),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: c.divider,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: PostActionBar(
                            likeCount: post.likeCount,
                            commentCount: state.comments.length,
                            likedByMe: state.likedByMe,
                            bookmarkedByMe: state.bookmarkedByMe,
                            onBookmarkTap: () => notifier.toggleBookmark(),
                            onLikeTap: () {
                              if (isPenalized) {
                                showAppSnackBar('제재 중에는 공감할 수 없어요.');
                                return;
                              }
                              notifier.toggleLike();
                            },
                            onShareTap: () {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: c.divider,
                          ),
                        ),
                        if (adsEnabled) ...[
                          const SchoolMainAdCard(
                            fullBleed: true,
                            placement: 'POST_DETAIL',
                          ),
                          const SizedBox(height: 8),
                        ],
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
                                if (isPenalized) {
                                  showAppSnackBar('제재 중에는 댓글을 작성할 수 없어요.');
                                  return;
                                }
                                notifier.startReply(
                                  commentId,
                                  isReply: isReply,
                                );
                                _scrollReplyTargetIntoView(commentId);
                              },
                              onCommentLikeTap: (commentId) {
                                if (isPenalized) {
                                  showAppSnackBar('제재 중에는 공감할 수 없어요.');
                                  return;
                                }
                                notifier.likeComment(commentId);
                              },
                              likedCommentIds: state.likedCommentIds,
                              onCommentChatTap: (comment) async {
                                if (isPenalized) {
                                  showAppSnackBar('제재 중에는 채팅을 시작할 수 없어요.');
                                  return;
                                }
                                if (comment.isMine) {
                                  showAppSnackBar('자신의 댓글에는 채팅할 수 없어요.');
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
                                _showReportSheet(
                                  context,
                                  onSubmit: (reason) {
                                    notifier.reportComment(commentId, reason);
                                  },
                                );
                              },
                              onCommentEditTap: (comment) {
                                if (!commentEditingEnabled) {
                                  return;
                                }
                                if (isPenalized) {
                                  showAppSnackBar('제재 중에는 댓글을 수정할 수 없어요.');
                                  return;
                                }
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
                                final confirmed =
                                    await _showDeleteConfirmDialog(
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
                                if (confirmed == true && mounted) {
                                  try {
                                    await ref
                                        .read(blockActionProvider)
                                        .block(authorUserId);
                                    if (mounted) {
                                      showAppSnackBar('해당 사용자를 차단했어요.');
                                      await notifier.loadPostDetail();
                                    }
                                  } catch (_) {
                                    if (mounted) {
                                      showAppSnackBar(
                                        '차단 처리에 실패했어요.',
                                        backgroundColor: const Color(
                                          0xFFE05C7B,
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
          ),
          if (!isPenalized)
            CommentInputBar(
              anonymous: state.commentAnonymous,
              isSubmitting: state.isSubmittingComment,
              replyingToCommentId: state.replyingToCommentId,
              onAnonymousChanged: notifier.toggleCommentAnonymous,
              onSubmit: notifier.submitComment,
              onCancelReply: notifier.cancelReply,
            ),
        ],
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
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              '아직 댓글이 없어요.\n첫 댓글을 남겨보세요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.captionLarge.copyWith(
                color: const Color(0xFF7D8790),
                height: 1.5,
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
          KeyedSubtree(
            key: _commentKeys.putIfAbsent(parent.commentId, () => GlobalKey()),
            child: CommentItem(
              comment: parent,
              replies: replies,
              likedByMe: likedCommentIds.contains(parent.commentId),
              isReplyTarget: replyingToCommentId == parent.commentId,
              onReplyTap: () => onReplyTap(parent.commentId, false),
              onLikeTap: () => onCommentLikeTap(parent.commentId),
              onReplyLikeTap: onCommentLikeTap,
              onChatTap: onCommentChatTap,
              onReportTap: onCommentReportTap,
              onEditTap: commentEditingEnabled ? onCommentEditTap : null,
              onDeleteTap: onCommentDeleteTap,
              onBlockTap: onCommentBlockTap,
            ),
          ),
          if (index != parents.length - 1)
            Divider(height: 1, thickness: 1, color: context.colors.dividerBlue),
        ],
      );
    }).toList();
  }

  void _scrollReplyTargetIntoView(int commentId) {
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      _liftCommentAboveKeyboard(commentId);
    });
  }

  void _liftCommentAboveKeyboard(int commentId) {
    final targetContext = _commentKeys[commentId]?.currentContext;
    if (targetContext == null || !_scrollController.hasClients) return;

    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final media = MediaQuery.of(context);
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final keyboardTop = media.size.height - media.viewInsets.bottom;
    final reservedInputHeight = media.viewInsets.bottom > 0 ? 130.0 : 88.0;
    final visibleBottom = keyboardTop - reservedInputHeight;
    final overflow = bottom - visibleBottom;

    if (overflow <= 0) return;

    final position = _scrollController.position;
    final targetOffset = (position.pixels + overflow + 10).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((targetOffset - position.pixels).abs() < 1) return;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
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
      showAppSnackBar(
        '채팅을 시작할 수 없어요: $e',
        backgroundColor: const Color(0xFFE05C7B),
      );
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
          style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
        ),
        const SizedBox(width: 6),
        Text(
          '$commentCount',
          style: AppTextStyles.labelMedium.copyWith(
            color: const Color(0xFF14A3F7),
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
      style: AppTextStyles.labelMedium.copyWith(
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
      title: Text('사용자 차단'),
      content: Text('이 사용자를 차단하면 해당 사용자의 게시글과 댓글이 보이지 않습니다.\n차단하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            '차단하기',
            style: AppTextStyles.bodyMedium.copyWith(color: Color(0xFFE05C5C)),
          ),
        ),
      ],
    ),
  );
}

/// 신고 사유 선택 바텀시트
void _showReportSheet(
  BuildContext context, {
  required ValueChanged<String> onSubmit,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.colors.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      const reasons = [
        ('SPAM', '스팸'),
        ('ABUSE', '욕설/모욕'),
        ('OBSCENE', '음란물/선정적 내용'),
        ('ILLEGAL', '불법 콘텐츠'),
        ('HARASSMENT', '괴롭힘'),
        ('ETC', '기타'),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '신고 사유 선택',
                style: AppTextStyles.titleLarge.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.$2),
                  onTap: () {
                    Navigator.pop(context);
                    onSubmit(r.$1);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제'),
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
  return showDialog<void>(
    context: context,
    builder: (_) => _CommentEditDialog(
      initialContent: initialContent,
      initialAnonymous: initialAnonymous,
      onSubmit: onSubmit,
    ),
  );
}

class _CommentEditDialog extends StatefulWidget {
  final String initialContent;
  final bool initialAnonymous;
  final void Function(String content, bool anonymous) onSubmit;

  const _CommentEditDialog({
    required this.initialContent,
    required this.initialAnonymous,
    required this.onSubmit,
  });

  @override
  State<_CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends State<_CommentEditDialog> {
  late final TextEditingController _controller;
  late bool _anonymous;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _anonymous = widget.initialAnonymous;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('댓글 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
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
                  value: _anonymous,
                  onChanged: (v) => setState(() => _anonymous = v ?? true),
                ),
                const Text('익명으로 수정'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            final content = _controller.text.trim();
            if (content.isEmpty) return;
            Navigator.pop(context);
            widget.onSubmit(content, _anonymous);
          },
          child: const Text('수정'),
        ),
      ],
    );
  }
}
