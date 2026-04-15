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
    final likeColor =
    likedByMe ? const Color(0xFF14A3F7) : const Color(0xFF6E7B87);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _ActionChip(
                icon: likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                label: '공감 $likeCount',
                color: likeColor,
                backgroundColor: likedByMe
                    ? const Color(0xFFEAF7FF)
                    : Colors.white,
                borderColor: likedByMe
                    ? const Color(0xFFBFE6FF)
                    : const Color(0xFFE6EDF3),
                onTap: onLikeTap,
              ),
              const SizedBox(width: 8),
              _StaticChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: '댓글 $commentCount',
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _IconActionButton(
          icon: Icons.ios_share_rounded,
          onTap: onShareTap,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StaticChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6E7B87)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6E7B87),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE6EDF3)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF6E7B87),
        ),
      ),
    );
  }
}