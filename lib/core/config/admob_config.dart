import 'dart:io';

import 'package:flutter/foundation.dart';

enum AdMobPlacement { homeFeed, postDetail }

class AdMobConfig {
  static const _androidHomeFeedBannerUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_HOME_FEED_BANNER_UNIT_ID',
  );
  static const _androidPostDetailBannerUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_POST_DETAIL_BANNER_UNIT_ID',
  );
  static const _iosHomeFeedBannerUnitId = String.fromEnvironment(
    'ADMOB_IOS_HOME_FEED_BANNER_UNIT_ID',
  );
  static const _iosPostDetailBannerUnitId = String.fromEnvironment(
    'ADMOB_IOS_POST_DETAIL_BANNER_UNIT_ID',
  );

  static const _testBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';

  static String? bannerUnitId(AdMobPlacement placement) {
    if (!kReleaseMode) return _testBannerUnitId;

    final value = switch (placement) {
      AdMobPlacement.homeFeed when Platform.isAndroid =>
        _androidHomeFeedBannerUnitId,
      AdMobPlacement.postDetail when Platform.isAndroid =>
        _androidPostDetailBannerUnitId,
      AdMobPlacement.homeFeed when Platform.isIOS => _iosHomeFeedBannerUnitId,
      AdMobPlacement.postDetail when Platform.isIOS =>
        _iosPostDetailBannerUnitId,
      _ => '',
    };

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
