import 'package:flutter/material.dart';
import '../../../../models/comment_model.dart';

// V3: 토스/카카오 스타일 — 개별 카드, 큰 원형 아바타, pill 형태 답글/공감 버튼
class CommentItemV3 extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> replies;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;
  final void Function(CommentModel comment)? onEditTap;
  final void Function(int commentId)? onDeleteTap;
  final void Function(int commentId)? onReportTap;
  final VoidCallback? onChatTap;

  const CommentItemV3({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
            if (replies.isNotEmpty) ...[
              Container(height: 1, color: const Color(0xFFF0F7FF),
                  margin: const EdgeInsets.symmetric(horizontal: 14)),
              ...replies.map(
                (reply) => Padding(
                  padding: const EdgeInsets.fromLTRB(28, 10, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 15,
                          color: Color(0xFF90CBF0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CommentBody(
                          comment: reply,
                          showReplyButton: false,
                          isMyComment: reply.isMine,
                          onLikeTap: () {},
                          onEditTap: () => onEditTap?.call(reply),
                          onDeleteTap: () =>
                              onDeleteTap?.call(reply.commentId),
                          onReportTap: () =>
                              onReportTap?.call(reply.commentId),
                          onChatTap: onChatTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
          width: 36, height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFCEE8F5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded,
              color: Color(0xFF3A9BD5), size: 20),
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
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827))),
                  const SizedBox(width: 6),
                  Text(createdAtText,
                      style: const TextStyle(fontSize: 11,
                          color: Color(0xFF9CA3AF))),
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
                        const PopupMenuItem(value: 'delete',
                            child: Text('삭제하기')),
                      ],
                      const PopupMenuItem(value: 'chat', child: Text('채팅')),
                      const PopupMenuItem(value: 'report',
                          child: Text('신고하기')),
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
                const SizedBox(height: 6),
                Text(comment.content,
                    style: const TextStyle(fontSize: 14, height: 1.6,
                        color: Color(0xFF374151))),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (showReplyButton) ...[
                    // 답글 — 테마색 pill
                    _PillActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '답글',
                      color: const Color(0xFF1A7FC1),
                      bgColor: const Color(0xFFF3F9FF),
                      onTap: onReplyTap,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // 공감 — pill, 카운트 있으면 파란색
                  _PillActionButton(
                    icon: comment.likeCount > 0
                        ? Icons.thumb_up
                        : Icons.thumb_up_alt_outlined,
                    label: comment.likeCount > 0
                        ? '${comment.likeCount}'
                        : '공감',
                    color: comment.likeCount > 0
                        ? const Color(0xFF1A7FC1)
                        : const Color(0xFF4B5563),
                    bgColor: comment.likeCount > 0
                        ? const Color(0xFFF3F9FF)
                        : const Color(0xFFF3F4F6),
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
          width: 36, height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4F8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded,
              color: Color(0xFFBCC8D4), size: 20),
        ),
        const SizedBox(width: 10),
        const Text('삭제된 댓글입니다.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic)),
      ],
    );
  }
}

// 답글/공감용 pill 버튼
class _PillActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _PillActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
