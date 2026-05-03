import 'package:flutter/material.dart';
import '../../models/comment_model.dart';

/// 댓글 및 대댓글 아이템 위젯
class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> replies;
  final bool likedByMe;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;
  final void Function(CommentModel comment)? onEditTap;
  final void Function(int commentId)? onDeleteTap;
  final void Function(int commentId)? onReportTap;
  final VoidCallback? onChatTap;
  final void Function(int authorUserId)? onBlockTap;

  const CommentItem({
    super.key,
    required this.comment,
    required this.replies,
    this.likedByMe = false,
    this.onReplyTap,
    this.onLikeTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onReportTap,
    this.onChatTap,
    this.onBlockTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          _CommentBody(
            comment: comment,
            showReplyButton: !comment.isReply,
            isMyComment: comment.isMine,
            likedByMe: likedByMe,
            onReplyTap: onReplyTap,
            onLikeTap: onLikeTap,
            onEditTap: () => onEditTap?.call(comment),
            onDeleteTap: () => onDeleteTap?.call(comment.commentId),
            onReportTap: () => onReportTap?.call(comment.commentId),
            onChatTap: onChatTap,
            onBlockTap: comment.authorUserId != null
                ? () => onBlockTap?.call(comment.authorUserId!)
                : null,
          ),
          if (replies.isNotEmpty) const SizedBox(height: 14),
          if (replies.isNotEmpty)
            ...replies.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(left: 12, top: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEAF0F5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 18,
                          color: Color(0xFF9AA7B2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _CommentBody(
                          comment: reply,
                          showReplyButton: false,
                          isMyComment: reply.isMine,
                          likedByMe: false,
                          onLikeTap: () {},
                          onEditTap: () => onEditTap?.call(reply),
                          onDeleteTap: () => onDeleteTap?.call(reply.commentId),
                          onReportTap: () => onReportTap?.call(reply.commentId),
                          onChatTap: onChatTap,
                          onBlockTap: reply.authorUserId != null
                              ? () => onBlockTap?.call(reply.authorUserId!)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 댓글 본문과 액션 영역
class _CommentBody extends StatelessWidget {
  final CommentModel comment;
  final bool showReplyButton;
  final bool isMyComment;
  final bool likedByMe;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onBlockTap;

  const _CommentBody({
    required this.comment,
    required this.showReplyButton,
    required this.isMyComment,
    required this.likedByMe,
    this.onReplyTap,
    this.onLikeTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onReportTap,
    this.onChatTap,
    this.onBlockTap,
  });

  @override
  Widget build(BuildContext context) {
    if (comment.isDeleted) {
      return _DeletedCommentPlaceholder();
    }

    final createdAtText =
        (comment.createdAt != null && comment.createdAt!.isNotEmpty)
            ? comment.createdAt!
            : '방금 전';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFF8EA2B5),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          comment.displayAuthorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F6FA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            createdAtText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7D8790),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 댓글 메뉴 — 내 댓글: 수정/삭제/채팅/신고, 타인: 채팅/신고/차단
                  PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEditTap?.call();
                        case 'delete':
                          onDeleteTap?.call();
                        case 'chat':
                          onChatTap?.call();
                        case 'report':
                          onReportTap?.call();
                        case 'block':
                          onBlockTap?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (isMyComment) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('수정하기'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('삭제하기'),
                        ),
                      ],
                      if (!isMyComment) ...[
                        const PopupMenuItem(
                          value: 'chat',
                          child: Text('채팅'),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('신고하기'),
                        ),
                        if (onBlockTap != null)
                          const PopupMenuItem(
                            value: 'block',
                            child: Text(
                              '차단하기',
                              style: TextStyle(color: Color(0xFFE05C5C)),
                            ),
                          ),
                      ],
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: Color(0xFF7D8790),
                      ),
                    ),
                  ),
                ],
              ),
              if (comment.content.isNotEmpty) const SizedBox(height: 8),
              if (comment.content.isNotEmpty)
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF2F3740),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (showReplyButton)
                    _InlineActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '답글',
                      onTap: onReplyTap,
                      isActive: false,
                    ),
                  if (showReplyButton) const SizedBox(width: 10),
                  _InlineActionButton(
                    icon: likedByMe
                        ? Icons.thumb_up_alt
                        : Icons.thumb_up_alt_outlined,
                    label: '공감 ${comment.likeCount}',
                    onTap: onLikeTap,
                    isActive: likedByMe,
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

/// 삭제된 댓글 플레이스홀더 (대댓글이 있어서 남겨두는 경우)
class _DeletedCommentPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFFBCC8D4),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '삭제된 댓글입니다.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF95A3AF),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// 댓글 하단 액션 버튼
class _InlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF14A3F7) : const Color(0xFF7D8790);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
