import 'package:flutter/material.dart';
import '../../models/comment_model.dart';

/// 댓글 및 대댓글 아이템 위젯
class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> replies;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const CommentItem({
    super.key,
    required this.comment,
    required this.replies,
    this.onReplyTap,
    this.onLikeTap,
    this.onReportTap,
    this.onEditTap,
    this.onDeleteTap,
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
            onReplyTap: onReplyTap,
            onLikeTap: onLikeTap,
            onReportTap: onReportTap,
            onEditTap: onEditTap,
            onDeleteTap: onDeleteTap,
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
                          onLikeTap: () {},
                          onReportTap: () {},
                          onEditTap: () {},
                          onDeleteTap: () {},
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
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const _CommentBody({
    required this.comment,
    required this.showReplyButton,
    this.onReplyTap,
    this.onLikeTap,
    this.onReportTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final createdAtText =
    (comment.createdAt != null && comment.createdAt!.isNotEmpty)
        ? comment.createdAt!
        : '방금 전';
    final isDeletedStyle = comment.author.contains('(삭제)');

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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDeletedStyle
                                ? const Color(0xFF95A3AF)
                                : const Color(0xFF111111),
                          ),
                        ),
                        if (!isDeletedStyle)
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

                  /// 댓글 수정/삭제 메뉴
                  PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEditTap?.call();
                      } else if (value == 'delete') {
                        onDeleteTap?.call();
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
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDeletedStyle
                        ? const Color(0xFF95A3AF)
                        : const Color(0xFF2F3740),
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
                    ),
                  if (showReplyButton) const SizedBox(width: 10),
                  _InlineActionButton(
                    icon: Icons.thumb_up_alt_outlined,
                    label: '공감 ${comment.likeCount}',
                    onTap: onLikeTap,
                  ),
                  const SizedBox(width: 10),
                  _InlineActionButton(
                    icon: Icons.flag_outlined,
                    label: '신고',
                    onTap: onReportTap,
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

/// 댓글 하단 액션 버튼
class _InlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF7D8790),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7D8790),
              ),
            ),
          ],
        ),
      ),
    );
  }
}