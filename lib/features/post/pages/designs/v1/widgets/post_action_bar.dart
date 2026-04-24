import 'package:flutter/material.dart';

// V1: 플랫 버튼 스타일 — pill 제거, 아이콘+숫자 텍스트만
class PostActionBarV1 extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final VoidCallback onLikeTap;
  final VoidCallback onShareTap;

  const PostActionBarV1({
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
        likedByMe ? const Color(0xFF14A3F7) : const Color(0xFF546E7A);

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                _FlatActionButton(
                  icon: likedByMe
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  label: '$likeCount',
                  color: likeColor,
                  onTap: onLikeTap,
                ),
                _FlatActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '$commentCount',
                  color: const Color(0xFF546E7A),
                  onTap: null,
                ),
                const Spacer(),
                _FlatIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: onShareTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _FlatActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _FlatIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FlatIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Icon(icon, size: 20, color: const Color(0xFF546E7A)),
      ),
    );
  }
}
