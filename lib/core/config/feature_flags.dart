const bool adsEnabled = bool.fromEnvironment('ADS_ENABLED', defaultValue: true);

const bool admobEnabled = bool.fromEnvironment(
  'ADMOB_ENABLED',
  defaultValue: true,
);

const bool partnerAdsEnabled = bool.fromEnvironment(
  'PARTNER_ADS_ENABLED',
  defaultValue: false,
);

const bool commentEditingEnabled = bool.fromEnvironment(
  'COMMENT_EDITING_ENABLED',
  defaultValue: false,
);

const bool postSharingEnabled = bool.fromEnvironment(
  'POST_SHARING_ENABLED',
  defaultValue: true,
);
