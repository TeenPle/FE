import 'package:go_router/go_router.dart';
import '../features/post/pages/post_detail_page.dart';
import '../features/post/pages/write_post_page.dart';
import '../features/school/pages/board_detail_page.dart';
import '../features/school/pages/school_page.dart';
import '../features/search/pages/search_page.dart';

/// 앱 전체 라우터 설정
final router = GoRouter(
  initialLocation: '/school',
  routes: [
    GoRoute(
      path: '/school',

      /// 학교 메인 화면으로 이동
      builder: (context, state) => const SchoolPage(),
    ),
    GoRoute(
      path: '/post/:postId',

      /// 게시글 상세 화면으로 이동
      builder: (context, state) {
        final postId = int.parse(state.pathParameters['postId']!);
        return PostDetailPage(postId: postId);
      },
    ),
    GoRoute(
      path: '/write-post',

      /// 게시글 작성 화면으로 이동
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return WritePostPage(
          boardId: extra['boardId'] as int,
          boardTitle: extra['boardTitle'] as String,
        );
      },
    ),
    GoRoute(
      path: '/board/:boardId',

      /// 특정 게시판 상세 목록 화면으로 이동
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BoardDetailPage(
          boardId: extra['boardId'] as int,
          boardTitle: extra['boardTitle'] as String,
        );
      },
    ),
    GoRoute(
      path: '/search',

      /// 검색 화면으로 이동
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SearchPage(
          initialKeyword: extra?['keyword'] as String?,
        );
      },
    ),
  ],
);