import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../form/comment_input_bar.dart';
import '../../../models/comment_model.dart';
import '../../../provider/post_detail_providers.dart';
import '../../../../profile/provider/block_provider.dart';
import 'widgets/comment_item.dart';
import 'widgets/post_action_bar.dart';
import 'widgets/post_content_card.dart';
import '../../write_post_page.dart';

// V3: 토스/카카오 소프트 카드 스타일
// - 배경: 연한 하늘색(F0F7FF), AppBar 흰색
// - 게시글/댓글 모두 그림자 카드 (padding 16)
// - 답글/공감 pill 버튼으로 명확한 tap 영역
class PostDetailPageV3 extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailPageV3({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailPageV3> createState() => _PostDetailPageV3State();
}

class _PostDetailPageV3State extends ConsumerState<PostDetailPageV3> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(postDetailProvider(widget.postId).notifier).loadPostDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailProvider(widget.postId));
    final notifier = ref.read(postDetailProvider(widget.postId).notifier);
    final post = state.post;

    ref.listen(postDetailProvider(widget.postId), (previous, next) async {
      if (!mounted) return;
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        notifier.clearMessages();
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.successMessage!)));
        notifier.clearMessages();
      }
      if (next.shouldClosePage &&
          next.shouldClosePage != previous?.shouldClosePage) {
        notifier.clearClosePageFlag();
        if (mounted) context.pop(true);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        centerTitle: true,
        title: const Text(
          '게시글',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_horiz, color: Color(0xFF111827)),
            onSelected: (value) async {
              if (value == 'edit' && post != null) {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => WritePostPage(
                      boardId: 0, boardTitle: '게시글 수정',
                      isEditMode: true, postId: post.postId,
                      initialTitle: post.title,
                      initialContent: post.content,
                      initialAnonymous: post.anonymous,
                      initialMediaList: post.mediaList,
                    ),
                  ),
                );
                if (updated == true) await notifier.loadPostDetail();
              } else if (value == 'delete') {
                final confirmed = await _showDeleteConfirmDialog(context,
                    title: '게시글을 삭제할까요?',
                    description: '삭제한 게시글은 되돌릴 수 없습니다.');
                if (confirmed == true) await notifier.deletePost();
              } else if (value == 'chat') {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('채팅 기능은 준비 중입니다.')));
              } else if (value == 'report') {
                _showReportSheet(context,
                    onSubmit: (reason) => notifier.reportPost(reason));
              } else if (value == 'block' && post?.authorUserId != null) {
                final confirmed = await _showBlockConfirmDialog(context);
                if (confirmed == true && mounted) {
                  try {
                    await ref.read(blockActionProvider).block(post!.authorUserId!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('해당 유저를 차단했습니다.')));
                      context.pop(true);
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('차단에 실패했습니다.')));
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              if (post != null && post.isMine) ...[
                const PopupMenuItem(value: 'edit', child: Text('수정하기')),
                const PopupMenuItem(value: 'delete', child: Text('삭제하기')),
              ],
              if (post == null || !post.isMine) ...[
                const PopupMenuItem(value: 'chat', child: Text('채팅')),
                const PopupMenuItem(value: 'report', child: Text('신고하기')),
                if (post != null && post.authorUserId != null)
                  const PopupMenuItem(
                    value: 'block',
                    child: Text('차단하기', style: TextStyle(color: Color(0xFFE05C5C))),
                  ),
              ],
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
              child: Text(state.errorMessage ?? '게시글을 불러오지 못했습니다.',
                  style: const TextStyle(color: Color(0xFF374151))))
          : RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  // 게시글 카드
                  PostContentCardV3(post: post),
                  // 액션바 카드
                  PostActionBarV3(
                    likeCount: post.likeCount,
                    commentCount: state.comments.length,
                    likedByMe: state.likedByMe,
                    onLikeTap: notifier.toggleLike,
                    onShareTap: () {},
                  ),
                  const SizedBox(height: 16),
                  // 댓글 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Text('댓글',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827))),
                        const SizedBox(width: 5),
                        Text('${state.comments.length}',
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A7FC1))),
                      ],
                    ),
                  ),
                  // 댓글 카드 리스트
                  ..._buildCommentWidgets(
                    context: context,
                    comments: state.comments,
                    onReplyTap: (id, _) =>
                        notifier.startReply(id, isReply: false),
                    onCommentLikeTap: notifier.likeComment,
                    onCommentChatTap: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('채팅 기능은 준비 중입니다.'))),
                    onCommentReportTap: (id) => _showReportSheet(context,
                        onSubmit: (r) => notifier.reportComment(id, r)),
                    onCommentEditTap: (comment) =>
                        _showEditCommentDialog(context,
                            initialContent: comment.content,
                            initialAnonymous: comment.anonymous,
                            onSubmit: (c, a) => notifier.updateComment(
                                commentId: comment.commentId,
                                content: c, anonymous: a)),
                    onCommentDeleteTap: (id) async {
                      final ok = await _showDeleteConfirmDialog(context,
                          title: '댓글을 삭제할까요?',
                          description: '삭제한 댓글은 되돌릴 수 없습니다.');
                      if (ok == true) await notifier.deleteComment(id);
                    },
                    onCommentBlockTap: (authorUserId) async {
                      final confirmed = await _showBlockConfirmDialog(context);
                      if (confirmed == true && mounted) {
                        try {
                          await ref.read(blockActionProvider).block(authorUserId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('해당 유저를 차단했습니다.')));
                            await notifier.loadPostDetail();
                          }
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('차단에 실패했습니다.')));
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildCommentWidgets({
    required BuildContext context,
    required List<CommentModel> comments,
    required void Function(int, bool) onReplyTap,
    required void Function(int) onCommentLikeTap,
    required VoidCallback onCommentChatTap,
    required void Function(int) onCommentReportTap,
    required void Function(CommentModel) onCommentEditTap,
    required void Function(int) onCommentDeleteTap,
    required void Function(int authorUserId) onCommentBlockTap,
  }) {
    final parents = comments.where((e) => e.parentId == null).toList();

    if (parents.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8BBFE0).withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('아직 댓글이 없어요.\n첫 댓글을 남겨보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5,
                      color: Color(0xFF9CA3AF))),
            ),
          ),
        ),
      ];
    }

    return parents.map((parent) {
      final replies =
          comments.where((e) => e.parentId == parent.commentId).toList();
      return CommentItemV3(
        comment: parent,
        replies: replies,
        onReplyTap: () => onReplyTap(parent.commentId, false),
        onLikeTap: () => onCommentLikeTap(parent.commentId),
        onChatTap: onCommentChatTap,
        onReportTap: onCommentReportTap,
        onEditTap: onCommentEditTap,
        onDeleteTap: onCommentDeleteTap,
        onBlockTap: onCommentBlockTap,
      );
    }).toList();
  }
}

Future<bool?> _showBlockConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('유저 차단'),
      content: const Text('이 유저를 차단하면 해당 유저의 게시글과 댓글이 더 이상 보이지 않습니다.\n차단하시겠습니까?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE05C5C)),
            child: const Text('차단하기')),
      ],
    ),
  );
}

void _showReportSheet(BuildContext context,
    {required ValueChanged<String> onSubmit}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      final reasons = ['SPAM', 'ABUSE', 'SEXUAL', 'VIOLENCE', 'ETC'];
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('신고 사유 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: Color(0xFF111827))),
              const SizedBox(height: 16),
              ...reasons.map((r) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r),
                onTap: () { Navigator.pop(context); onSubmit(r); },
              )),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool?> _showDeleteConfirmDialog(BuildContext context,
    {required String title, required String description}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제')),
      ],
    ),
  );
}

Future<void> _showEditCommentDialog(BuildContext context,
    {required String initialContent, required bool initialAnonymous,
      required void Function(String, bool) onSubmit}) {
  final controller = TextEditingController(text: initialContent);
  bool anonymous = initialAnonymous;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        title: const Text('댓글 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, maxLines: 4, minLines: 2,
                decoration: const InputDecoration(
                    hintText: '댓글 내용을 입력하세요',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(
                  value: anonymous,
                  onChanged: (v) =>
                      setLocalState(() => anonymous = v ?? true)),
              const Text('익명으로 수정'),
            ]),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소')),
          TextButton(
              onPressed: () {
                final c = controller.text.trim();
                if (c.isEmpty) return;
                Navigator.pop(dialogContext);
                onSubmit(c, anonymous);
              },
              child: const Text('수정')),
        ],
      ),
    ),
  );
}
