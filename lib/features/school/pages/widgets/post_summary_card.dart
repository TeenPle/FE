import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/time_format.dart';
import '../../models/post_summary.dart';

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

  String get _likeText => post.likeCount >= 100 ? '100+' : '${post.likeCount}';

  String get _commentText =>
      post.commentCount >= 50 ? '50+' : '${post.commentCount}';

  String get _timeLabel {
    final dt = parseCreatedAtMs(post.createdAtMs);
    if (dt == null) return '';
    return timeAgo(dt);
  }

  Color get _categoryColor {
    final label = categoryLabel ?? '';
    if (label.contains('질문')) return const Color(0xFF8C63D8);
    if (label.contains('정보')) return const Color(0xFF18A999);
    if (label.contains('연애')) return const Color(0xFFFF5F7E);
    if (label.contains('학교') || label.contains('생활')) {
      return const Color(0xFFFF9E2C);
    }
    return const Color(0xFF229BF3);
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = _thumbnailUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetaRow(
                          author: post.displayAuthorName,
                          timeLabel: _timeLabel,
                          categoryLabel: categoryLabel,
                          categoryColor: _categoryColor,
                        ),
                        const SizedBox(height: 10),
                        _TitleLine(title: post.title, hot: hot, hasPoll: post.hasPoll),
                        const SizedBox(height: 4),
                        Text(
                          post.content,
                          maxLines: thumbnailUrl == null ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF59616C),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (thumbnailUrl != null) ...[
                    const SizedBox(width: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        width: 96,
                        height: 88,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 96,
                          height: 88,
                          color: const Color(0xFFEFF4F8),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 96,
                          height: 88,
                          color: const Color(0xFFE4EAF0),
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: Color(0xFF9AA7B2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ReactionMetric(
                    icon: Icons.chat_bubble_outline_rounded,
                    text: _commentText,
                    color: const Color(0xFF229BF3),
                  ),
                  const SizedBox(width: 18),
                  _ReactionMetric(
                    icon: Icons.favorite_border_rounded,
                    text: _likeText,
                    color: const Color(0xFFFF5B6D),
                  ),
                ],
              ),
              if (showDivider) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFEAF1F7)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String author;
  final String timeLabel;
  final String? categoryLabel;
  final Color categoryColor;

  const _MetaRow({
    required this.author,
    required this.timeLabel,
    required this.categoryLabel,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFE7EAEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 17,
            color: Color(0xFF9AA1AA),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF151515),
              letterSpacing: 0,
            ),
          ),
        ),
        if (timeLabel.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8F9298),
              letterSpacing: 0,
            ),
          ),
        ],
        if (categoryLabel != null && categoryLabel!.isNotEmpty) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                categoryLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: categoryColor,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TitleLine extends StatelessWidget {
  final String title;
  final bool hot;
  final bool hasPoll;

  const _TitleLine({required this.title, required this.hot, this.hasPoll = false});

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
                  const TextSpan(
                    text: 'HOT ',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF6B35),
                      letterSpacing: 0,
                    ),
                  ),
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF050505),
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
            child: const Text(
              '투표',
              style: TextStyle(
                fontSize: 11,
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

class _ReactionMetric extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ReactionMetric({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
