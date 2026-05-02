import '../models/board_post_page.dart';
import '../models/hot_filter.dart';
import '../models/post_sort_type.dart';
import '../models/post_summary.dart';
import '../models/school_response.dart';

/// 학교/게시판 목록 관련 추상 Repository
abstract class SchoolRepository {
  /// 학교 상세와 기본 게시판 게시글을 함께 조회
  Future<SchoolResponse> getSchoolDetail({
    required int schoolId,
    int page = 0,
    int size = 10,
  });

  /// 게시판별 게시글 목록을 페이지 단위로 조회
  Future<BoardPostPage> getPostsByBoard({
    required int boardId,
    required PostSortType sortType,
    int page = 0,
    int size = 10,
  });

  /// HOT 게시글 목록 조회
  Future<List<PostSummary>> getHotPosts({
    required int schoolId,
    required HotFilter filter,
    int size = 20,
  });
}