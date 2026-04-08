import 'package:flutter/material.dart';
import '../../models/post_summary.dart';

class PostSummaryCard extends StatelessWidget {
  final PostSummary post;
  final VoidCallback? onTap;
  final bool showDivider;

  const PostSummaryCard({
    super.key,
    required this.post,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            post.displayAuthorName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8D8D8D),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '|',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB0B0B0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '조회 ${post.viewCount}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8D8D8D),
                            ),
                          ),
                          const Spacer(),
                          _MetaIconText(
                            icon: Icons.favorite_border,
                            text: '${post.likeCount}',
                            color: const Color(0xFFFF7E7E),
                          ),
                          const SizedBox(width: 10),
                          _MetaIconText(
                            icon: Icons.chat_bubble_outline,
                            text: '${post.commentCount}',
                            color: const Color(0xFF3DA9F5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showDivider) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaIconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaIconText({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}