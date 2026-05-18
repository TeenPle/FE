import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SchoolMainAdCard extends StatelessWidget {
  final bool fullBleed;

  const SchoolMainAdCard({super.key, this.fullBleed = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(fullBleed ? 0 : 16);

    return Container(
      color: c.pageBg,
      padding: fullBleed
          ? const EdgeInsets.fromLTRB(0, 14, 0, 12)
          : const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Material(
        color: c.cardBg,
        borderRadius: radius,
        child: InkWell(
          onTap: () {},
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: c.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: Color(0xFF12A66A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4DF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'AD',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 9,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB26A00),
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '학교생활 제휴 안내',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: c.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '우리 학교 근처 혜택 모아보기',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: c.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '청소년 이용 가능 제휴만 검수해서 보여주는 테스트 광고 영역입니다.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: c.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFF9AA7B2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
