import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';
import '../models/board_post_page.dart';
import '../models/post_summary.dart';
import '../models/school_response.dart';

/// 학교/게시판 관련 실제 API 호출 담당 클래스
class SchoolApi {
  final AppApiClient client;

  const SchoolApi({
    required this.client,
  });

  /// 학교 상세와 기본 게시판 미리보기 데이터를 조회
  Future<SchoolResponse> getSchoolDetail({
    required int schoolId,
    int page = 0,
    int size = 10,
  }) async {
    final json = await client.get(
      '/api/schools/$schoolId',
      queryParameters: {
        'page': '$page',
        'size': '$size',
      },
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

    final response = ApiResponse.fromJson(
      json,
          (data) {
        final map = data as Map<String, dynamic>;
        final content = (map['content'] as List<dynamic>? ?? [])
            .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
            .toList();

        return BoardPostPage(
          posts: content,
          hasNext: map['hasNext'] as bool? ?? false,
        );
      },
    );

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  /// 최근 3일간 해당 학교의 좋아요 많은 순 인기글 조회
  Future<List<PostSummary>> getHotPosts({
    required int schoolId,
    int size = 5,
  }) async {
    final json = await client.get(
      '/api/schools/$schoolId/posts/hot',
      queryParameters: {'size': '$size'},
    );

    final response = ApiResponse.fromJson(
      json,
      (data) => data == null
          ? <PostSummary>[]
          : (data as List<dynamic>)
              .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

    if (!response.isSuccess) {
      throw Exception(response.message);
    }

    return response.result ?? [];
  }
}