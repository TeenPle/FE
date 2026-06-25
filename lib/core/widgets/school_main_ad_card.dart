import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/feature_flags.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../features/ad/models/ad_banner_model.dart';
import '../../features/ad/provider/ad_banner_provider.dart';

class SchoolMainAdCard extends ConsumerWidget {
  final bool fullBleed;
  final String placement;

  const SchoolMainAdCard({
    super.key,
    this.fullBleed = false,
    this.placement = 'HOME_FEED',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!adsEnabled) return const SizedBox.shrink();

    final adState = ref.watch(activeAdProvider(placement));

    // 광고는 운영 데이터에 의존하므로 실패하거나 등록된 광고가 없으면 지면을 접는다.
    // 피드/상세 UX가 광고 API 장애 때문에 깨지지 않도록 의도적으로 조용히 숨긴다.
    return adState.maybeWhen(
      data: (ad) => ad == null
          ? const SizedBox.shrink()
          : _SchoolAdSurface(ad: ad, fullBleed: fullBleed),
      error: (_, _) => const SizedBox.shrink(),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _SchoolAdSurface extends StatelessWidget {
  final AdBannerModel ad;
  final bool fullBleed;

  const _SchoolAdSurface({required this.ad, required this.fullBleed});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(fullBleed ? 0 : 16);
    final hasLink = ad.linkUrl != null && ad.linkUrl!.trim().isNotEmpty;

    return Container(
      color: c.pageBg,
      padding: fullBleed
          ? const EdgeInsets.fromLTRB(0, 14, 0, 12)
          : const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Material(
        color: c.cardBg,
        borderRadius: radius,
        child: InkWell(
          onTap: hasLink ? () => _openAdLink(ad.linkUrl!) : null,
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
                _AdThumbnail(imageUrl: ad.imageUrl),
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
                              _placementLabel(ad.placement),
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
                        ad.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: c.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ad.subtitle,
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
                if (hasLink)
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

  Future<void> _openAdLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _placementLabel(String placement) {
    return switch (placement) {
      'POST_DETAIL' => '게시글 제휴 안내',
      _ => '학교생활 제휴 안내',
    };
  }
}

class _AdThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _AdThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: url == null || url.isEmpty
          ? const Icon(
              Icons.local_offer_outlined,
              color: Color(0xFF12A66A),
              size: 22,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.local_offer_outlined,
                color: Color(0xFF12A66A),
                size: 22,
              ),
            ),
    );
  }
}
