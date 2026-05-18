import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';

class PostListSkeleton extends StatelessWidget {
  final int count;

  const PostListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: List.generate(count, (i) {
          return Column(
            children: [
              _PostSkeletonItem(),
              if (i < count - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: c.borderSubtle,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF252D3A) : const Color(0xFFEEEEEE),
      highlightColor: isDark
          ? const Color(0xFF2E3848)
          : const Color(0xFFF8F8F8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: w * 0.55, height: 16),
                const SizedBox(height: 8),
                _SkeletonBox(width: double.infinity, height: 13),
                const SizedBox(height: 4),
                _SkeletonBox(width: w * 0.72, height: 13),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SkeletonBox(width: w * 0.18, height: 11),
                    const SizedBox(width: 12),
                    _SkeletonBox(width: w * 0.12, height: 11),
                    const Spacer(),
                    _SkeletonBox(width: w * 0.11, height: 11),
                  ],
                ),
              ],
            );
          },
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
