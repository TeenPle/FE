import 'package:flutter/material.dart';

// V3: 토스/카카오 스타일 — 카드 내부 테마색 pill 버튼, 소프트 액션
class PostActionBarV3 extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final VoidCallback onLikeTap;
  final VoidCallback onShareTap;

  const PostActionBarV3({
    super.key,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.onLikeTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8BBFE0).withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 공감 — pill 스타일, 활성 시 테마색
            GestureDetector(
              onTap: onLikeTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: likedByMe
                      ? const Color(0xFFF3F9FF)
                      : const Color(0xFFF5F8FB),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: likedByMe
                        ? const Color(0xFF90CBF0)
                        : const Color(0xFFE2EAF0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 17,
                      color: likedByMe
                          ? const Color(0xFF1A7FC1)
                          : const Color(0xFF546E7A),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$likeCount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: likedByMe
                            ? const Color(0xFF1A7FC1)
                            : const Color(0xFF546E7A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 댓글 수 — pill 스타일 (정적)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FB),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE2EAF0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 17, color: Color(0xFF546E7A)),
                  const SizedBox(width: 5),
                  Text(
                    '$commentCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF546E7A),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 공유
            GestureDetector(
              onTap: onShareTap,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FB),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2EAF0)),
                ),
                child: const Icon(Icons.ios_share_rounded,
                    size: 18, color: Color(0xFF546E7A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
