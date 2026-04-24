import 'package:flutter/material.dart';

// V2: 블라인드 스타일 — 아이콘+숫자 플랫, 구분선 심플
class PostActionBarV2 extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final VoidCallback onLikeTap;
  final VoidCallback onShareTap;

  const PostActionBarV2({
    super.key,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.onLikeTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final likeActive = const Color(0xFF0969DA);
    final likeInactive = const Color(0xFF57606A);

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // 공감 버튼
                GestureDetector(
                  onTap: onLikeTap,
                  child: Row(
                    children: [
                      Icon(
                        likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 18,
                        color: likedByMe ? likeActive : likeInactive,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$likeCount',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: likedByMe ? likeActive : likeInactive,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // 세로 구분선
                Container(width: 1, height: 14, color: const Color(0xFFD0D7DE),
                    margin: const EdgeInsets.symmetric(horizontal: 12)),
                // 댓글 수
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: Color(0xFF57606A)),
                    const SizedBox(width: 5),
                    Text(
                      '$commentCount',
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF57606A)),
                    ),
                  ],
                ),
                const Spacer(),
                // 공유
                GestureDetector(
                  onTap: onShareTap,
                  child: const Icon(Icons.ios_share_rounded,
                      size: 20, color: Color(0xFF57606A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
