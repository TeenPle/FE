import '../models/board_post_page.dart';
import '../models/post_sort_type.dart';
import '../models/school_response.dart';
import 'school_api.dart';
import 'school_repository.dart';

/// 실제 서버와 연결되는 학교 Repository 구현체
class LiveSchoolRepository implements SchoolRepository {
  final SchoolApi api;

  const LiveSchoolRepository({
    required this.api,
  });

  /// 학교 상세 정보를 서버에서 조회
  @override
  Future<SchoolResponse> getSchoolDetail({
    required int schoolId,
    int page = 0,
    int size = 10,
  }) {
    return api.getSchoolDetail(
      schoolId: schoolId,
      page: page,
      size: size,
    );
  }

  /// 특정 게시판 글 목록을 서버에서 조회
  @override
  Future<BoardPostPage> getPostsByBoard({
    required int boardId,
    required PostSortType sortType,
    int page = 0,
    int size = 10,
  }) {
    final sortBy = sortType == PostSortType.popular ? 'likeCount' : 'createdAt';
    const sortDirection = 'DESC';

    return api.getPostsByBoard(
      boardId: boardId,
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
    );
  }
}