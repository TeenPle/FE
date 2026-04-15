import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../form/comment_input_bar.dart';
import '../models/comment_model.dart';
import '../models/post_detail.dart';
import '../provider/post_detail_providers.dart';
import 'widgets/comment_item.dart';
import 'widgets/post_action_bar.dart';
import 'widgets/post_content_card.dart';
import 'write_post_page.dart';

/// 게시글 상세 페이지
class PostDetailPage extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailPage({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  @override
  void initState() {
    super.initState();

    debugPrint('PostDetailPage 진입 postId = ${widget.postId}');

    /// 진입 시 게시글 상세 조회
    Future.microtask(() {
      ref.read(postDetailProvider(widget.postId).notifier).loadPostDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailProvider(widget.postId));
    final notifier = ref.read(postDetailProvider(widget.postId).notifier);
    final post = state.post;

    debugPrint('현재 화면 postId=${state.postId}, postTitle=${state.post?.title}');

    ref.listen(postDetailProvider(widget.postId), (previous, next) async {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        notifier.clearMessages();
      }

      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        notifier.clearMessages();
      }

      /// 게시글 삭제 후 이전 화면으로 이동
      if (next.shouldClosePage && next.shouldClosePage != previous?.shouldClosePage) {
        notifier.clearClosePageFlag();
        if (mounted) context.pop(true);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7FAFC),
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: const Text(
          '게시글',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_horiz, color: Color(0xFF111111)),
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
              } else if (value == 'report') {
                _showReportSheet(
                  context,
                  onSubmit: (reason) {
                    notifier.reportPost(reason);
                  },
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('수정하기'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('삭제하기'),
              ),
              PopupMenuItem(
                value: 'report',
                child: Text('신고하기'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CommentInputBar(
        anonymous: state.commentAnonymous,
        isSubmitting: state.isSubmittingComment,
        replyingToCommentId: state.replyingToCommentId,
        onAnonymousChanged: notifier.toggleCommentAnonymous,
        onSubmit: notifier.submitComment,
        onCancelReply: notifier.cancelReply,
      ),
      body: state.isLoading && post == null
          ? const Center(child: CircularProgressIndicator())
          : post == null
          ? Center(
        child: Text(
          state.errorMessage ?? '게시글을 불러오지 못했습니다.',
          style: const TextStyle(color: Color(0xFF222222)),
        ),
      )
          : RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            PostContentCard(post: post),
            const SizedBox(height: 12),
            PostActionBar(
              likeCount: post.likeCount,
              commentCount: state.comments.length,
              likedByMe: state.likedByMe,
              onLikeTap: notifier.toggleLike,
              onShareTap: () {
                debugPrint('share post: ${post.postId}');
              },
            ),
            const SizedBox(height: 20),
            _CommentSectionHeader(commentCount: state.comments.length),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE6EDF3),
                ),
              ),
              child: Column(
                children: _buildCommentWidgets(
                  comments: state.comments,
                  onReplyTap: (commentId, isReply) {
                    notifier.startReply(commentId, isReply: isReply);
                  },
                  onCommentLikeTap: notifier.likeComment,
                  onCommentReportTap: (commentId) {
                    _showReportSheet(
                      context,
                      onSubmit: (reason) {
                        notifier.reportComment(commentId, reason);
                      },
                    );
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
    required void Function(int commentId, bool isReply) onReplyTap,
    required void Function(int commentId) onCommentLikeTap,
    required void Function(int commentId) onCommentReportTap,
    required void Function(CommentModel comment) onCommentEditTap,
    required void Function(int commentId) onCommentDeleteTap,
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
                fontSize: 14,
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
      final replies =
      comments.where((e) => e.parentId == parent.commentId).toList();

      return Column(
        children: [
          CommentItem(
            comment: parent,
            replies: replies,
            onReplyTap: () => onReplyTap(parent.commentId, false),
            onLikeTap: () => onCommentLikeTap(parent.commentId),
            onReportTap: () => onCommentReportTap(parent.commentId),
            onEditTap: () => onCommentEditTap(parent),
            onDeleteTap: () => onCommentDeleteTap(parent.commentId),
          ),
          if (index != parents.length - 1)
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF0F4F8),
            ),
        ],
      );
    }).toList();
  }
}

/// 댓글 섹션 헤더
class _CommentSectionHeader extends StatelessWidget {
  final int commentCount;

  const _CommentSectionHeader({
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '댓글',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$commentCount',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14A3F7),
          ),
        ),
      ],
    );
  }
}

/// 신고 사유 선택 바텀시트
void _showReportSheet(
    BuildContext context, {
      required ValueChanged<String> onSubmit,
    }) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final reasons = [
        'SPAM',
        'ABUSE',
        'SEXUAL',
        'VIOLENCE',
        'ETC',
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '신고 사유 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                    (reason) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason),
                  onTap: () {
                    Navigator.pop(context);
                    onSubmit(reason);
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
  );
}