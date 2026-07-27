import 'package:flutter/material.dart';

import '../config/admob_config.dart';
import '../config/feature_flags.dart';
import 'admob_banner_ad.dart';
import 'school_main_ad_card.dart';

class TeenpleAdSlot extends StatelessWidget {
  final AdMobPlacement placement;
  final bool fullBleed;

  const TeenpleAdSlot({
    super.key,
    required this.placement,
    this.fullBleed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!adsEnabled) return const SizedBox.shrink();

    if (admobEnabled) {
      return AdMobBannerAd(placement: placement, fullBleed: fullBleed);
    }

    if (partnerAdsEnabled) {
      return SchoolMainAdCard(
        fullBleed: fullBleed,
        placement: switch (placement) {
          AdMobPlacement.homeFeed => 'HOME_FEED',
          AdMobPlacement.postDetail => 'POST_DETAIL',
        },
      );
    }

    return const SizedBox.shrink();
  }
}
