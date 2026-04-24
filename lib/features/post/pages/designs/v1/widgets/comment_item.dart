import 'package:flutter/material.dart';
import '../../../../models/comment_model.dart';

// V1: 원형 아바타 + 들여쓰기 답글 + 답글/공감 버튼 가시성 개선
class CommentItemV1 extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> replies;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;
  final void Function(CommentModel comment)? onEditTap;
  final void Function(int commentId)? onDeleteTap;
  final void Function(int commentId)? onReportTap;
  final VoidCallback? onChatTap;

  const CommentItemV1({
    super.key,
    required this.comment,
    required this.replies,
    this.onReplyTap,
    this.onLikeTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onReportTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: _CommentBody(
            comment: comment,
            showReplyButton: !comment.isReply,
            isMyComment: comment.isMine,
            onReplyTap: onReplyTap,
            onLikeTap: onLikeTap,
            onEditTap: () => onEditTap?.call(comment),
            onDeleteTap: () => onDeleteTap?.call(comment.commentId),
            onReportTap: () => onReportTap?.call(comment.commentId),
            onChatTap: onChatTap,
          ),
        ),
        if (replies.isNotEmpty)
          ...replies.map(
            (reply) => Container(
              color: const Color(0xFFF8FBFE),
              padding: const EdgeInsets.fromLTRB(28, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.subdirectory_arrow_right_rounded,
                        size: 16, color: Color(0xFFB0C4CE)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CommentBody(
                      comment: reply,
                      showReplyButton: false,
                      isMyComment: reply.isMine,
                      onLikeTap: () {},
                      onEditTap: () => onEditTap?.call(reply),
                      onDeleteTap: () => onDeleteTap?.call(reply.commentId),
                      onReportTap: () => onReportTap?.call(reply.commentId),
                      onChatTap: onChatTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CommentBody extends StatelessWidget {
  final CommentModel comment;
  final bool showReplyButton;
  final bool isMyComment;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onChatTap;

  const _CommentBody({
    required this.comment,
    required this.showReplyButton,
    required this.isMyComment,
    this.onReplyTap,
    this.onLikeTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onReportTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    if (comment.isDeleted) return _DeletedCommentPlaceholder();

    final createdAtText =
        (comment.createdAt != null && comment.createdAt!.isNotEmpty)
            ? comment.createdAt!
            : '방금 전';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFDDEEF9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded,
              color: Color(0xFF7DA9C8), size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(comment.displayAuthorName,
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111))),
                  const SizedBox(width: 6),
                  Text(createdAtText,
                      style: const TextStyle(fontSize: 11,
                          color: Color(0xFF95A3AF))),
                  const Spacer(),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit': onEditTap?.call();
                        case 'delete': onDeleteTap?.call();
                        case 'chat': onChatTap?.call();
                        case 'report': onReportTap?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (isMyComment) ...[
                        const PopupMenuItem(value: 'edit', child: Text('수정하기')),
                        const PopupMenuItem(value: 'delete', child: Text('삭제하기')),
                      ],
                      const PopupMenuItem(value: 'chat', child: Text('채팅')),
                      const PopupMenuItem(value: 'report', child: Text('신고하기')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.more_horiz_rounded,
                          size: 16, color: Color(0xFFB0BEC5)),
                    ),
                  ),
                ],
              ),
              if (comment.content.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(comment.content,
                    style: const TextStyle(fontSize: 14, height: 1.55,
                        color: Color(0xFF2F3740))),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (showReplyButton) ...[
                    // 답글 — 테마 파란색으로 명확하게
                    _InlineActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '답글',
                      color: const Color(0xFF2980B9),
                      onTap: onReplyTap,
                    ),
                    const SizedBox(width: 12),
                  ],
                  // 공감 — 더 진한 색으로
                  _InlineActionButton(
                    icon: comment.likeCount > 0
                        ? Icons.thumb_up
                        : Icons.thumb_up_alt_outlined,
                    label: comment.likeCount > 0
                        ? '${comment.likeCount}'
                        : '공감',
                    color: comment.likeCount > 0
                        ? const Color(0xFF2980B9)
                        : const Color(0xFF4D6475),
                    onTap: onLikeTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeletedCommentPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4F8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded,
              color: Color(0xFFBCC8D4), size: 20),
        ),
        const SizedBox(width: 10),
        const Text('삭제된 댓글입니다.',
            style: TextStyle(fontSize: 13, color: Color(0xFF95A3AF),
                fontStyle: FontStyle.italic)),
      ],
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
