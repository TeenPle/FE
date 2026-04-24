import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../form/comment_input_bar.dart';
import '../../../models/comment_model.dart';
import '../../../provider/post_detail_providers.dart';
import 'widgets/comment_item.dart';
import 'widgets/post_action_bar.dart';
import 'widgets/post_content_card.dart';
import '../../write_post_page.dart';

// V2: 블라인드/LinkedIn 스타일
// - 배경: 순백(white), AppBar 하단 border
// - 제목 → 작성자 순서 (본문 먼저)
// - 풀너비, 섹션 구분은 얇은 divider만
class PostDetailPageV2 extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailPageV2({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailPageV2> createState() => _PostDetailPageV2State();
}

class _PostDetailPageV2State extends ConsumerState<PostDetailPageV2> {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D1117),
        centerTitle: false,
        title: const Text(
          '게시글',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: Color(0xFF0D1117)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEAECEF)),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_horiz, color: Color(0xFF0D1117)),
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
              }
            },
            itemBuilder: (context) => [
              if (post != null && post.isMine) ...[
                const PopupMenuItem(value: 'edit', child: Text('수정하기')),
                const PopupMenuItem(value: 'delete', child: Text('삭제하기')),
              ],
              const PopupMenuItem(value: 'chat', child: Text('채팅')),
              const PopupMenuItem(value: 'report', child: Text('신고하기')),
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
                  style: const TextStyle(color: Color(0xFF24292F))))
          : RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  PostContentCardV2(post: post),
                  PostActionBarV2(
                    likeCount: post.likeCount,
                    commentCount: state.comments.length,
                    likedByMe: state.likedByMe,
                    onLikeTap: notifier.toggleLike,
                    onShareTap: () {},
                  ),
                  const Divider(height: 8, thickness: 8,
                      color: Color(0xFFF6F8FA)),
                  // 댓글 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        const Text('댓글',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D1117))),
                        const SizedBox(width: 5),
                        Text('${state.comments.length}',
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0969DA))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1,
                      color: Color(0xFFEAECEF)),
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
                  ),
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
  }) {
    final parents = comments.where((e) => e.parentId == null).toList();

    if (parents.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text('아직 댓글이 없어요.\n첫 댓글을 남겨보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5,
                    color: Color(0xFF8B949E))),
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
          CommentItemV2(
            comment: parent,
            replies: replies,
            onReplyTap: () => onReplyTap(parent.commentId, false),
            onLikeTap: () => onCommentLikeTap(parent.commentId),
            onChatTap: onCommentChatTap,
            onReportTap: onCommentReportTap,
            onEditTap: onCommentEditTap,
            onDeleteTap: onCommentDeleteTap,
          ),
          if (index != parents.length - 1)
            const Divider(height: 1, thickness: 1,
                color: Color(0xFFF6F8FA)),
        ],
      );
    }).toList();
  }
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
                      color: Color(0xFF0D1117))),
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
