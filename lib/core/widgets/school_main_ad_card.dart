import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../features/ad/models/ad_banner_model.dart';
import '../../features/ad/provider/ad_banner_provider.dart';

class SchoolMainAdCard extends ConsumerWidget {
  final bool fullBleed;
  final String placement;
  final bool showAdMobTestFallback;

  const SchoolMainAdCard({
    super.key,
    this.fullBleed = false,
    this.placement = 'HOME_FEED',
    this.showAdMobTestFallback = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adState = ref.watch(activeAdProvider(placement));

    // 광고는 운영 데이터에 의존하므로 실패하거나 등록된 광고가 없으면 지면을 접는다.
    // 피드/상세 UX가 광고 API 장애 때문에 깨지지 않도록 의도적으로 조용히 숨긴다.
    return adState.maybeWhen(
      data: (ad) => ad == null
          ? _fallbackAdMobTestBanner()
          : _SchoolAdSurface(ad: ad, fullBleed: fullBleed),
      error: (_, _) => _fallbackAdMobTestBanner(),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _fallbackAdMobTestBanner() {
    // 디버그에서만 기본 노출한다. 운영 빌드에서 테스트 광고를 띄우려면
    // --dart-define=ENABLE_ADMOB_TEST_ADS=true 를 명시적으로 넣는다.
    const enabledByDefine = bool.fromEnvironment('ENABLE_ADMOB_TEST_ADS');
    final enabled = showAdMobTestFallback && (kDebugMode || enabledByDefine);
    if (!enabled) return const SizedBox.shrink();
    return _AdMobTestBanner(fullBleed: fullBleed, placement: placement);
  }
}

class _AdMobTestBanner extends StatefulWidget {
  final bool fullBleed;
  final String placement;

  const _AdMobTestBanner({required this.fullBleed, required this.placement});

  @override
  State<_AdMobTestBanner> createState() => _AdMobTestBannerState();
}

class _AdMobTestBannerState extends State<_AdMobTestBanner> {
  static const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  BannerAd? _bannerAd;
  AdSize? _platformAdSize;
  int? _requestedWidth;
  bool _isLoaded = false;

  void _loadBanner(double availableWidth) async {
    final width = availableWidth.truncate();
    if (width <= 0 || _requestedWidth == width) return;

    final adSize = AdSize.largeBanner;
    if (width < adSize.width) return;

    _requestedWidth = width;
    await _bannerAd?.dispose();
    if (!mounted) return;
    setState(() {
      _bannerAd = null;
      _platformAdSize = null;
      _isLoaded = false;
    });

    final banner = BannerAd(
      // Google 공식 테스트 배너 ID. 실제 출시 광고 ID로 교체하면 안 되는 검증 전용 값이다.
      adUnitId: _testBannerAdUnitId,
      request: const AdRequest(),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          if (!mounted) return;
          final bannerAd = ad as BannerAd;
          setState(() {
            _bannerAd = bannerAd;
            _platformAdSize = adSize;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted && _bannerAd == null) {
            setState(() {
              _isLoaded = false;
            });
          }
          if (kDebugMode) {
            debugPrint(
              '[AdMob] test adaptive banner failed: '
              'code=${error.code}, domain=${error.domain}, message=${error.message}',
            );
          }
        },
      ),
    );
    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = widget.fullBleed ? 0.0 : 36.0;
        final availableWidth = constraints.maxWidth - horizontalPadding;
        final availableWidthInt = availableWidth.truncate();
        if (availableWidthInt > 0 && _requestedWidth != availableWidthInt) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadBanner(availableWidth);
          });
        }

        final ad = _bannerAd;
        final adSize = _platformAdSize;
        if (!_isLoaded || ad == null || adSize == null) {
          return kDebugMode
              ? _AdMobDebugBox(
                  fullBleed: widget.fullBleed,
                  text: 'AdMob test ad loading',
                )
              : const SizedBox.shrink();
        }

        return Container(
          color: context.colors.pageBg,
          padding: widget.fullBleed
              ? const EdgeInsets.fromLTRB(0, 12, 0, 12)
              : const EdgeInsets.fromLTRB(18, 12, 18, 12),
          alignment: Alignment.center,
          child: SizedBox(
            width: adSize.width.toDouble(),
            height: adSize.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        );
      },
    );
  }
}

class _AdMobDebugBox extends StatelessWidget {
  final bool fullBleed;
  final String text;

  const _AdMobDebugBox({required this.fullBleed, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.pageBg,
      padding: fullBleed
          ? const EdgeInsets.fromLTRB(0, 12, 0, 12)
          : const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(fullBleed ? 0 : 12),
          border: Border.all(color: const Color(0xFFFFD88A)),
        ),
        child: Text(
          text,
          style: AppTextStyles.captionSmall.copyWith(
            color: const Color(0xFF9A5B00),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
