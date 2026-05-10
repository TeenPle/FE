import 'package:flutter/material.dart';

import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/like_burst_button.dart';
import '../../../../core/widgets/tap_scale.dart';

class PostActionBar extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final bool bookmarkedByMe;
  final VoidCallback onLikeTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onShareTap;

  const PostActionBar({
    super.key,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.bookmarkedByMe,
    required this.onLikeTap,
    required this.onBookmarkTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              LikeBurstButton(
                liked: likedByMe,
                likeCount: likeCount,
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
        const SizedBox(width: 8),
        _IconActionButton(
          icon: bookmarkedByMe
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          iconColor: bookmarkedByMe
              ? const Color(0xFFF5A623)
              : const Color(0xFF6E7B87),
          backgroundColor: bookmarkedByMe
              ? const Color(0xFFFFF8ED)
              : Colors.white,
          borderColor: bookmarkedByMe
              ? const Color(0xFFFFE0A0)
              : const Color(0xFFE6EDF3),
          onTap: onBookmarkTap,
        ),
        const SizedBox(width: 8),
        _IconActionButton(
          icon: Icons.ios_share_rounded,
          onTap: onShareTap,
        ),
      ],
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
              fontSize: 12,
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
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const _IconActionButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      scale: 0.90,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor ?? const Color(0xFFE6EDF3)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? const Color(0xFF6E7B87),
          ),
        ),
      ),
    );
  }
}
