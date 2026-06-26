/// 게시글 목록 정렬 타입
enum PostSortType { latest, popular }

extension PostSortTypeX on PostSortType {
  /// UI에 표시할 한글 라벨
  String get label {
    switch (this) {
      case PostSortType.latest:
        return '최신순';
      case PostSortType.popular:
        return '인기순';
    }
  }

  /// 백엔드 정렬 파라미터로 변환할 때 사용할 값
  String get queryValue {
    switch (this) {
      case PostSortType.latest:
        return 'createdAt,DESC';
      case PostSortType.popular:
        return 'likeCount,DESC';
    }
  }
}
