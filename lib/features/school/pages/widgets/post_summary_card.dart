import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:teenple_frontend/core/theme/app_text_styles.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../models/post_summary.dart';

const Color _likeAccentColor = Color(0xFFE2556F);
const Color _commentAccentColor = Color(0xFF2F80ED);

class PostSummaryCard extends StatelessWidget {
  final PostSummary post;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool compact;
  final String? categoryLabel;
  final bool hot;

  const PostSummaryCard({
    super.key,
    required this.post,
    this.onTap,
    this.showDivider = true,
    this.compact = false,
    this.categoryLabel,
    this.hot = false,
  });

  String? get _thumbnailUrl {
    for (final media in post.mediaList) {
      if (media.isImage) return media.url;
    }
    return null;
  }

  String get _viewText =>
      post.viewCount >= 9999 ? '9999+' : '${post.viewCount}';
  String get _likeText => post.likeCount >= 100 ? '100+' : '${post.likeCount}';
  String get _commentText =>
      post.commentCount >= 50 ? '50+' : '${post.commentCount}';

  String get _timeLabel {
    final dt = parseCreatedAtMs(post.createdAtMs);
    if (dt == null) return '';
    return timeAgo(dt);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final thumbnailUrl = _thumbnailUrl;

    return TapScale(
      scale: 0.97,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  AppHaptics.selection();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TitleLine(
                              title: post.title,
                              hot: hot,
                              hasPoll: post.hasPoll,
                              textPrimary: c.textPrimary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post.content,
                              maxLines: thumbnailUrl == null ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w400,
                                color: c.textSecondary,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _BoardMetaRow(
                              categoryLabel: categoryLabel,
                              timeLabel: _timeLabel,
                              color: c.textTertiary,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _StatChip(
                                  icon: Icons.remove_red_eye_outlined,
                                  text: _viewText,
                                  color: c.iconOnCard,
                                  emphasized: post.viewCount > 0,
                                ),
                                const SizedBox(width: 10),
                                _StatChip(
                                  icon: Icons.favorite_border_rounded,
                                  text: _likeText,
                                  color: _likeAccentColor,
                                  emphasized: post.likeCount > 0,
                                ),
                                const SizedBox(width: 10),
                                _StatChip(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  text: _commentText,
                                  color: post.commentCount > 0
                                      ? _commentAccentColor
                                      : c.iconMuted,
                                  emphasized: post.commentCount > 0,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (thumbnailUrl != null) ...[
                        const SizedBox(width: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            width: 82,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(width: 82, color: c.subtleBg),
                            errorWidget: (context, url, error) => Container(
                              width: 82,
                              color: c.border,
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: c.iconSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showDivider) ...[
                  const SizedBox(height: 8),
                  Divider(height: 1, color: c.divider),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardMetaRow extends StatelessWidget {
  final String? categoryLabel;
  final String timeLabel;
  final Color color;

  const _BoardMetaRow({
    required this.categoryLabel,
    required this.timeLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (categoryLabel != null && categoryLabel!.isNotEmpty) {
      parts.add(categoryLabel!);
    }
    if (timeLabel.isNotEmpty) parts.add(timeLabel);

    return Text(
      parts.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0,
      ),
    );
  }
}

class _TitleLine extends StatelessWidget {
  final String title;
  final bool hot;
  final bool hasPoll;
  final Color textPrimary;

  const _TitleLine({
    required this.title,
    required this.hot,
    required this.textPrimary,
    this.hasPoll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                if (hot)
                  TextSpan(
                    text: 'HOT ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B35),
                      letterSpacing: 0,
                    ),
                  ),
                TextSpan(
                  text: title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasPoll) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF5FF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF229BF3), width: 1),
            ),
            child: Text(
              '투표',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF229BF3),
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool emphasized;

  const _StatChip({
    required this.icon,
    required this.text,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 11,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            color: color,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
