const bool adsEnabled = bool.fromEnvironment(
  'ADS_ENABLED',
  defaultValue: false,
);

const bool commentEditingEnabled = bool.fromEnvironment(
  'COMMENT_EDITING_ENABLED',
  defaultValue: false,
);

const bool postSharingEnabled = bool.fromEnvironment(
  'POST_SHARING_ENABLED',
  defaultValue: false,
);
