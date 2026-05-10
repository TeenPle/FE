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

  String get _viewText =>
      post.viewCount >= 9999 ? '9999+' : '${post.viewCount}';

  String get _likeText =>
      post.likeCount >= 100 ? '100+' : '${post.likeCount}';

  String get _commentText =>
      post.commentCount >= 50 ? '50+' : '${post.commentCount}';

  String get _timeLabel {
    final dt = parseCreatedAtMs(post.createdAtMs);
    if (dt == null) return '';
    return timeAgo(dt);
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
              // 이미지가 있을 경우 텍스트 영역 전체 높이에 맞춰 늘어나도록 IntrinsicHeight 사용
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1줄: 제목
                          _TitleLine(
                            title: post.title,
                            hot: hot,
                            hasPoll: post.hasPoll,
                          ),
                          const SizedBox(height: 5),
                          // 2줄: 본문 내용
                          Text(
                            post.content,
                            maxLines: thumbnailUrl == null ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF59616C),
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 7),
                          // 3줄: 게시판 이름 · 작성 시간 (일반 텍스트)
                          _BoardMetaRow(
                            categoryLabel: categoryLabel,
                            timeLabel: _timeLabel,
                          ),
                          const SizedBox(height: 6),
                          // 4줄: 조회수 · 공감수 · 댓글 수 (왼쪽 정렬)
                          Row(
                            children: [
                              _StatChip(
                                icon: Icons.remove_red_eye_outlined,
                                text: _viewText,
                              ),
                              const SizedBox(width: 10),
                              _StatChip(
                                icon: Icons.favorite_border_rounded,
                                text: _likeText,
                              ),
                              const SizedBox(width: 10),
                              _StatChip(
                                icon: Icons.chat_bubble_outline_rounded,
                                text: _commentText,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 이미지: 텍스트 전체 높이(4줄)에 맞춰 stretch
                    if (thumbnailUrl != null) ...[
                      const SizedBox(width: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          width: 90,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 90,
                            color: const Color(0xFFEFF4F8),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 90,
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
              ),
              if (showDivider) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEAF1F7)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 게시판 이름 · 작성 시간 (일반 텍스트, 컬러 없음) ─────────────

class _BoardMetaRow extends StatelessWidget {
  final String? categoryLabel;
  final String timeLabel;

  const _BoardMetaRow({
    required this.categoryLabel,
    required this.timeLabel,
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
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: Color(0xFF9AA7B2),
        letterSpacing: 0,
      ),
    );
  }
}

// ─── 제목 줄 (HOT 뱃지 · 투표 뱃지 포함) ──────────────────────────

class _TitleLine extends StatelessWidget {
  final String title;
  final bool hot;
  final bool hasPoll;

  const _TitleLine({
    required this.title,
    required this.hot,
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
                  const TextSpan(
                    text: 'HOT ',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B35),
                      letterSpacing: 0,
                    ),
                  ),
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
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

// ─── 조회수 / 공감수 / 댓글 수 아이콘+텍스트 칩 ──────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFABB5BF)),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Color(0xFFABB5BF),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
