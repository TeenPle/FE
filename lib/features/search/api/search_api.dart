import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';
import '../../school/models/board_post_page.dart';
import '../../school/models/post_summary.dart';

/// 검색 관련 실제 API 호출 담당 클래스
class SearchApi {
  final AppApiClient client;

  const SearchApi({required this.client});

  /// 키워드로 게시글 검색
  Future<BoardPostPage> searchPosts({
    required String keyword,
    int? boardId,
    required int page,
    required int size,
  }) async {
    final json = await client.get(
      '/api/search',
      queryParameters: {
        'keyword': keyword,
        if (boardId != null) 'boardId': '$boardId',
        'page': '$page',
        'size': '$size',
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
