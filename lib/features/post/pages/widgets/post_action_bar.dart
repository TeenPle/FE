import 'package:flutter/material.dart';

class PostActionBar extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final VoidCallback onLikeTap;
  final VoidCallback onShareTap;

  const PostActionBar({
    super.key,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.onLikeTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final likeColor = likedByMe
        ? const Color(0xFF14A3F7)
        : const Color(0xFF6E7B87);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          _ActionTextButton(
            icon: likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
            label: '공감',
            color: likeColor,
            onTap: onLikeTap,
          ),
          const SizedBox(width: 26),
          _StaticActionText(
            icon: Icons.chat_bubble_outline,
            label: '댓글 $commentCount',
          ),
          const SizedBox(width: 26),
          _ActionTextButton(
            icon: Icons.ios_share,
            label: '공유',
            color: const Color(0xFF6E7B87),
            onTap: onShareTap,
          ),
        ],
      ),
    );
  }
}

class _ActionTextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTextButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticActionText extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StaticActionText({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF6E7B87)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6E7B87),
          ),
        ),
      ],
    );
  }
}