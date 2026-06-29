import 'package:flutter/material.dart';
import 'package:teenple_frontend/core/config/feature_flags.dart';
import 'package:teenple_frontend/core/theme/app_text_styles.dart';

import '../../../../core/theme/app_colors.dart';
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
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LikeBurstButton(
                liked: likedByMe,
                likeCount: likeCount,
                onTap: onLikeTap,
              ),
              const SizedBox(width: 14),
              _StaticChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: '댓글 $commentCount',
                bgColor: c.tintBg,
                borderColor: c.borderBlue,
                iconColor: c.iconOnCard,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _IconActionButton(
          icon: bookmarkedByMe
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          iconColor: bookmarkedByMe ? const Color(0xFFF5A623) : c.iconOnCard,
          backgroundColor: bookmarkedByMe ? const Color(0xFFFFF8ED) : c.tintBg,
          borderColor: bookmarkedByMe ? const Color(0xFFFFE0A0) : c.borderBlue,
          onTap: onBookmarkTap,
        ),
        if (postSharingEnabled) ...[
          const SizedBox(width: 10),
          _IconActionButton(
            icon: Icons.ios_share_rounded,
            backgroundColor: c.tintBg,
            borderColor: c.borderBlue,
            iconColor: c.iconOnCard,
            onTap: onShareTap,
          ),
        ],
      ],
    );
  }
}

class _StaticChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;

  const _StaticChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: iconColor,
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
    final c = context.colors;
    return TapScale(
      scale: 0.90,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: backgroundColor ?? c.tintBg,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor ?? c.borderBlue),
          ),
          child: Icon(icon, size: 17, color: iconColor ?? c.iconOnCard),
        ),
      ),
    );
  }
}
