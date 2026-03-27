import 'package:flutter/material.dart';
import '../../models/post_summary.dart';

class PostSummaryCard extends StatelessWidget {
  final PostSummary post;
  final VoidCallback? onTap;

  const PostSummaryCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopRow(post: post),
            const SizedBox(height: 14),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            _BottomStats(post: post),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final PostSummary post;

  const _TopRow({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tag(
          text: post.anonymous ? '익명' : post.username,
          backgroundColor: const Color(0xFFF1F5F9),
          textColor: const Color(0xFF4B5563),
        ),
        const SizedBox(width: 8),
        _Tag(
          text: post.boardName,
          backgroundColor: const Color(0xFFE0F2FE),
          textColor: const Color(0xFF0284C7),
        ),
        const Spacer(),
        Text(
          post.createdAt,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _BottomStats extends StatelessWidget {
  final PostSummary post;

  const _BottomStats({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          icon: Icons.thumb_up_alt_outlined,
          color: const Color(0xFF2563EB),
          value: post.likeCount,
        ),
        const SizedBox(width: 14),
        _StatItem(
          icon: Icons.thumb_down_alt_outlined,
          color: const Color(0xFFEF4444),
          value: post.dislikeCount,
        ),
        const SizedBox(width: 14),
        _StatItem(
          icon: Icons.chat_bubble_outline,
          color: const Color(0xFF0EA5E9),
          value: post.commentCount,
        ),
        const SizedBox(width: 14),
        _StatItem(
          icon: Icons.remove_red_eye_outlined,
          color: const Color(0xFF6B7280),
          value: post.viewCount,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _Tag({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}