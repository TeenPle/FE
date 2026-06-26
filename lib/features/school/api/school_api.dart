import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';
import '../models/board_post_page.dart';
import '../models/hot_filter.dart';
import '../models/post_summary.dart';
import '../models/school_response.dart';

/// 학교/게시판 관련 실제 API 호출 담당 클래스
class SchoolApi {
  final AppApiClient client;

  const SchoolApi({required this.client});

  /// 학교 상세와 기본 게시판 미리보기 데이터를 조회
  Future<SchoolResponse> getSchoolDetail({
    required int schoolId,
    int page = 0,
    int size = 10,
  }) async {
    final json = await client.get(
      '/api/schools/$schoolId',
      queryParameters: {'page': '$page', 'size': '$size'},
    );

    final response = ApiResponse.fromJson(
      json,
      (data) => SchoolResponse.fromJson(data as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  /// 특정 게시판의 게시글 목록을 페이지 단위로 조회
  Future<BoardPostPage> getPostsByBoard({
    required int boardId,
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
  }) async {
    final json = await client.get(
      '/api/boards/$boardId/posts',
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      },
    );

    final response = ApiResponse.fromJson(json, (data) {
      final map = data as Map<String, dynamic>;
      final content = (map['content'] as List<dynamic>? ?? [])
          .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      return BoardPostPage(posts: content, hasNext: _hasNext(map));
    });

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  /// 학교 전체 게시판의 최신 게시글을 페이지 단위로 조회
  Future<BoardPostPage> getAllPostsBySchool({
    required int schoolId,
    int page = 0,
    int size = 10,
  }) async {
    final json = await client.get(
      '/api/schools/$schoolId/posts',
      queryParameters: {'page': '$page', 'size': '$size'},
    );

    final response = ApiResponse.fromJson(json, (data) {
      final map = data as Map<String, dynamic>;
      final content = (map['content'] as List<dynamic>? ?? [])
          .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      return BoardPostPage(posts: content, hasNext: _hasNext(map));
    });

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  /// HOT 게시글 목록 조회 (filter: TODAY / WEEK / ALL)
  Future<List<PostSummary>> getHotPosts({
    required int schoolId,
    required HotFilter filter,
    int size = 20,
  }) async {
    final json = await client.get(
      '/api/schools/$schoolId/posts/hot',
      queryParameters: {'filter': filter.queryValue, 'size': '$size'},
    );

    final response = ApiResponse.fromJson(
      json,
      (data) => (data as List<dynamic>)
          .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  Future<List<PostSummary>> getTopRecommendedPosts({
    required int schoolId,
    int hours = 3,
    int size = 3,
  }) async {
    final json = await client.get(
      '/api/schools/$schoolId/posts/top-recommended',
      queryParameters: {'hours': '$hours', 'size': '$size'},
    );

    final response = ApiResponse.fromJson(
      json,
      (data) => (data as List<dynamic>)
          .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  bool _hasNext(Map<String, dynamic> map) {
    if (map['hasNext'] is bool) {
      return map['hasNext'] as bool;
    }
    if (map['last'] is bool) {
      return !(map['last'] as bool);
    }
    return false;
  }
}
