import 'package:flutter/material.dart';
import '../../models/post_summary.dart';

/// 학교 메인 / 게시판 상세에서 공통으로 사용하는 게시글 카드
class PostSummaryCard extends StatelessWidget {
  final PostSummary post;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool compact;

  const PostSummaryCard({
    super.key,
    required this.post,
    this.onTap,
    this.showDivider = true,
    this.compact = false,
  });

  /// 첫 번째 이미지 URL (없으면 null)
  String? get _thumbnailUrl {
    for (final media in post.mediaList) {
      if (media.isImage) return media.url;
    }
    return null;
  }

  bool get _hasNonImageFile => post.mediaList.any((m) => !m.isImage);

  bool get _showThumbnailBox => _thumbnailUrl != null;

  /// 좋아요 수 텍스트를 화면용으로 변환
  String get _likeText {
    if (post.likeCount >= 100) return '100+';
    return '${post.likeCount}';
  }

  /// 댓글 수 텍스트를 화면용으로 변환
  String get _commentText {
    if (post.commentCount >= 50) return '50+';
    return '${post.commentCount}';
  }


  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: compact ? 16 : 17,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF111111),
      height: 1.2,
    );

    final contentStyle = TextStyle(
      fontSize: compact ? 14 : 15,
      color: const Color(0xFF222222),
      height: 1.35,
      fontWeight: FontWeight.w500,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          compact ? 14 : 16,
          18,
          compact ? 14 : 16,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showThumbnailBox) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _thumbnailUrl!,
                      width: compact ? 74 : 76,
                      height: compact ? 74 : 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: compact ? 74 : 76,
                        height: compact ? 74 : 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white54,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.content,
                        maxLines: compact ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: contentStyle,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            '방금 전',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E8E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '|',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFC3C3C3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.displayAuthorName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E8E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (_hasNonImageFile) ...[
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 14,
                              color: Color(0xFF9AA7B2),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _MetaText(
                            icon: Icons.favorite_border_rounded,
                            text: _likeText,
                            color: const Color(0xFFFF8E98),
                          ),
                          const SizedBox(width: 10),
                          _MetaText(
                            icon: Icons.chat_bubble_outline_rounded,
                            text: _commentText,
                            color: const Color(0xFF66BFF5),
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
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFDCDCDC),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 좋아요/댓글 수 표시용 메타 텍스트 위젯
class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaText({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}