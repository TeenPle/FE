import 'package:flutter/material.dart';
import '../../models/comment_model.dart';

class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> replies;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;

  const CommentItem({
    super.key,
    required this.comment,
    required this.replies,
    this.onReplyTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: _CommentBody(
              comment: comment,
              showReplyButton: !comment.isReply,
              onReplyTap: onReplyTap,
              onLikeTap: onLikeTap,
            ),
          ),
          if (replies.isNotEmpty)
            ...replies.map(
                  (reply) => Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.subdirectory_arrow_right,
                        size: 18,
                        color: Color(0xFF9AA7B2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CommentBody(
                        comment: reply,
                        showReplyButton: false,
                        onLikeTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(
            height: 1,
            thickness: 0.7,
            color: Color(0xFFDCE7F0),
          ),
        ],
      ),
    );
  }
}

class _CommentBody extends StatelessWidget {
  final CommentModel comment;
  final bool showReplyButton;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLikeTap;

  const _CommentBody({
    required this.comment,
    required this.showReplyButton,
    this.onReplyTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    final createdAtText = comment.createdAt ?? '';
    final isDeletedStyle = comment.author.contains('(삭제)');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFDDE7F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.displayAuthorName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDeletedStyle
                      ? const Color(0xFF95A3AF)
                      : const Color(0xFF111111),
                ),
              ),
              if (comment.content.isNotEmpty) const SizedBox(height: 6),
              if (comment.content.isNotEmpty)
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: isDeletedStyle
                        ? const Color(0xFF95A3AF)
                        : const Color(0xFF2F3740),
                  ),
                ),
              if (createdAtText.isNotEmpty) const SizedBox(height: 8),
              if (createdAtText.isNotEmpty)
                Text(
                  createdAtText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7D8790),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            if (showReplyButton)
              IconButton(
                onPressed: onReplyTap,
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF7D8790),
                  size: 21,
                ),
              ),
            IconButton(
              onPressed: onLikeTap,
              icon: const Icon(
                Icons.thumb_up_alt_outlined,
                color: Color(0xFF7D8790),
                size: 21,
              ),
            ),
          ],
        ),
      ],
    );
  }
}