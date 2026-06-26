enum HotFilter {
  today,
  week,
  all;

  String get label => switch (this) {
    HotFilter.today => '오늘',
    HotFilter.week => '이번주',
    HotFilter.all => '전체',
  };

  String get queryValue => switch (this) {
    HotFilter.today => 'TODAY',
    HotFilter.week => 'WEEK',
    HotFilter.all => 'ALL',
  };
}
