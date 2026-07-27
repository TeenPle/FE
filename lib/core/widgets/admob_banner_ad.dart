import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import '../theme/app_colors.dart';

class AdMobBannerAd extends StatefulWidget {
  final AdMobPlacement placement;
  final bool fullBleed;

  const AdMobBannerAd({
    super.key,
    required this.placement,
    this.fullBleed = false,
  });

  @override
  State<AdMobBannerAd> createState() => _AdMobBannerAdState();
}

class _AdMobBannerAdState extends State<AdMobBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final adUnitId = AdMobConfig.bannerUnitId(widget.placement);
    if (adUnitId == null) {
      if (kDebugMode) {
        debugPrint('[AdMob] missing ad unit id for ${widget.placement}');
      }
      return;
    }

    final adSize = switch (widget.placement) {
      AdMobPlacement.homeFeed => AdSize.banner,
      AdMobPlacement.postDetail => AdSize.mediumRectangle,
    };

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) {
            debugPrint(
              '[AdMob] failed to load ${widget.placement}: '
              'code=${error.code}, domain=${error.domain}, '
              'message=${error.message}',
            );
          }
        },
      ),
    );

    await banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();

    return Container(
      color: context.colors.pageBg,
      padding: widget.fullBleed
          ? const EdgeInsets.fromLTRB(0, 12, 0, 12)
          : const EdgeInsets.fromLTRB(18, 12, 18, 12),
      alignment: Alignment.center,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
