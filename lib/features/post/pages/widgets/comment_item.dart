import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../models/comment_model.dart';

/// 댓글 및 대댓글 아이템 위젯
class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> replies;
  final bool likedByMe;
  final bool isReplyTarget;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;
  final void Function(CommentModel comment)? onEditTap;
  final void Function(int commentId)? onDeleteTap;
  final void Function(int commentId)? onReportTap;
  final void Function(CommentModel comment)? onChatTap;
  final void Function(int authorUserId)? onBlockTap;

  const CommentItem({
    super.key,
    required this.comment,
    required this.replies,
    this.likedByMe = false,
    this.isReplyTarget = false,
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 11, 0, 11),
      child: Column(
        children: [
          _CommentBody(
            comment: comment,
            showReplyButton: !comment.isReply,
            isMyComment: comment.isMine,
            likedByMe: likedByMe,
            isReply: false,
            isReplyTarget: isReplyTarget,
            onReplyTap: onReplyTap,
            onLikeTap: onLikeTap,
            onEditTap: () => onEditTap?.call(comment),
            onDeleteTap: () => onDeleteTap?.call(comment.commentId),
            onReportTap: () => onReportTap?.call(comment.commentId),
            onChatTap: () => onChatTap?.call(comment),
            onBlockTap: comment.authorUserId != null
                ? () => onBlockTap?.call(comment.authorUserId!)
                : null,
          ),
          if (replies.isNotEmpty) const SizedBox(height: 10),
          if (replies.isNotEmpty)
            ...replies.map(
                  (reply) => Padding(
                padding: const EdgeInsets.only(left: 6, top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 18,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 17,
                          color: c.borderBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                        decoration: BoxDecoration(
                          color: c.replyBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: c.borderBlue,
                          ),
                        ),
                        child: _CommentBody(
                          comment: reply,
                          showReplyButton: false,
                          isMyComment: reply.isMine,
                          likedByMe: false,
                          isReply: true,
                          isReplyTarget: false,
                          onLikeTap: () {},
                          onEditTap: () => onEditTap?.call(reply),
                          onDeleteTap: () => onDeleteTap?.call(reply.commentId),
                          onReportTap: () => onReportTap?.call(reply.commentId),
                          onChatTap: () => onChatTap?.call(reply),
                          onBlockTap: reply.authorUserId != null
                              ? () => onBlockTap?.call(reply.authorUserId!)
                              : null,
                        ),
                      ),
                    ),
                  ],
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
  final bool isReply;
  final bool isReplyTarget;
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
    required this.isReply,
    required this.isReplyTarget,
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

    final c = context.colors;
    final createdAtText = () {
      final dt = parseCreatedAtMs(comment.createdAtMs);
      return dt != null ? timeAgo(dt) : '';
    }();

    final canReplyFromSurface = showReplyButton && onReplyTap != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: canReplyFromSurface
            ? () {
          AppHaptics.light();
          onReplyTap!();
        }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            isReplyTarget ? 12 : 0,
            isReplyTarget ? 12 : 0,
            isReplyTarget ? 12 : 0,
            isReplyTarget ? 12 : 0,
          ),
          decoration: BoxDecoration(
            color: isReplyTarget ? const Color(0xFFDFF0FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isReplyTarget
                ? Border.all(color: const Color(0xFF9BD0FF), width: 1.2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isReply ? 30 : 34,
                    height: isReply ? 30 : 34,
                    decoration: BoxDecoration(
                      color: isReply ? c.cardBg : const Color(0xFFE4F2FF),
                      borderRadius: BorderRadius.circular(isReply ? 10 : 12),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: const Color(0xFF8EA2B5),
                      size: isReply ? 18 : 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 3,
                      children: [
                        Text(
                          comment.displayAuthorName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                        if (createdAtText.isNotEmpty)
                          Text(
                            createdAtText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7D8790),
                            ),
                          ),
                      ],
                    ),
                  ),

                  /// 댓글 메뉴 — 내 댓글: 수정/삭제/채팅/신고, 타인: 채팅/신고/차단
                  PopupMenuButton<String>(
                    color: c.cardBg,
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
                          child: _CompactMenuText('수정하기'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: _CompactMenuText('삭제하기'),
                        ),
                      ],
                      if (!isMyComment) ...[
                        if (comment.canChatWithAuthor)
                          const PopupMenuItem(
                            value: 'chat',
                            child: _CompactMenuText('채팅'),
                          ),
                        if (comment.canReportAuthor)
                          const PopupMenuItem(
                            value: 'report',
                            child: _CompactMenuText('신고하기'),
                          ),
                        if (comment.canBlockAuthor && onBlockTap != null)
                          const PopupMenuItem(
                            value: 'block',
                            child: _CompactMenuText('차단하기', color: Color(0xFFE05C5C)),
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
              if (comment.content.isNotEmpty) const SizedBox(height: 5),
              if (comment.content.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: isReply ? 0 : 1),
                  child: Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.48,
                      color: Color(0xFF2F3740),
                      letterSpacing: 0,
                    ),
                  ),
                ),
              const SizedBox(height: 7),
              Padding(
                padding: EdgeInsets.only(left: isReply ? 0 : 1),
                child: Row(
                  children: [
                    if (showReplyButton)
                      _InlineActionButton(
                        icon: Icons.mode_comment_outlined,
                        label: '답글',
                        onTap: onReplyTap,
                        isActive: isReplyTarget,
                      ),
                    if (showReplyButton) const SizedBox(width: 8),
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
              ),
            ],
          ),
        ),
      ),
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
            fontSize: 12,
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

    return TapScale(
      scale: 0.90,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
          AppHaptics.light();
          onTap!();
        },
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactMenuText extends StatelessWidget {
  final String text;
  final Color color;

  const _CompactMenuText(
      this.text, {
        this.color = const Color(0xFF222222),
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}