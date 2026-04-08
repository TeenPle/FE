import 'package:go_router/go_router.dart';
import '../features/post/pages/post_detail_page.dart';
import '../features/school/pages/school_page.dart';

final router = GoRouter(
  initialLocation: '/school',
  routes: [
    GoRoute(
      path: '/school',
      builder: (context, state) => const SchoolPage(),
    ),
    GoRoute(
      path: '/post/:postId',
      builder: (context, state) {
        final postId = int.parse(state.pathParameters['postId']!);
        return PostDetailPage(postId: postId);
      },
    ),
  ],
);