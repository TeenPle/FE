import 'package:flutter_test/flutter_test.dart';
import 'package:teenple_frontend/features/admin/models/admin_content_model.dart';

void main() {
  group('AdminPostPageModel', () {
    test('서버가 계산한 전체·노출·숨김 개수를 파싱한다', () {
      final result = AdminPostPageModel.fromJson({
        'content': [
          _postJson(postId: 1, status: 'ACTIVE'),
          _postJson(postId: 2, status: 'HIDDEN'),
        ],
        'totalCount': 4,
        'visibleCount': 3,
        'hiddenCount': 1,
        'last': true,
      });

      expect(result.posts, hasLength(2));
      expect(result.totalCount, 4);
      expect(result.visibleCount, 3);
      expect(result.hiddenCount, 1);
      expect(result.isLast, isTrue);
    });

    test('구버전 Page 응답에서도 현재 페이지를 기준으로 안전하게 계산한다', () {
      final result = AdminPostPageModel.fromJson({
        'content': [
          _postJson(postId: 1, status: 'ACTIVE'),
          _postJson(postId: 2, status: 'HIDDEN'),
        ],
        'totalElements': 2,
        'last': true,
      });

      expect(result.totalCount, 2);
      expect(result.visibleCount, 1);
      expect(result.hiddenCount, 1);
    });
  });
}

Map<String, dynamic> _postJson({
  required int postId,
  required String status,
}) {
  return {
    'postId': postId,
    'title': '테스트 게시글',
    'contentPreview': '내용',
    'postStatus': status,
    'anonymous': false,
    'authorUserId': 1,
    'authorLabel': '관리자',
    'boardId': 10,
    'boardTitle': '자유게시판',
    'viewCount': 0,
    'likeCount': 0,
    'dislikeCount': 0,
    'commentCount': 0,
    'createdAt': '2026-07-29T12:00:00',
  };
}
