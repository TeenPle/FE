import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostListSkeleton extends StatelessWidget {
  final int count;

  const PostListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: List.generate(count, (i) {
          return Column(
            children: [
              _PostSkeletonItem(),
              if (i < count - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF0F4F8),
                  indent: 18,
                  endIndent: 18,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _PostSkeletonItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF8F8F8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(width: 180, height: 16),
            const SizedBox(height: 8),
            _SkeletonBox(width: double.infinity, height: 13),
            const SizedBox(height: 4),
            _SkeletonBox(width: 220, height: 13),
            const SizedBox(height: 12),
            Row(
              children: [
                _SkeletonBox(width: 60, height: 11),
                const SizedBox(width: 12),
                _SkeletonBox(width: 40, height: 11),
                const Spacer(),
                _SkeletonBox(width: 36, height: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
