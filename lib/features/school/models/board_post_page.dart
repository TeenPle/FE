import 'post_summary.dart';

/// 게시판 게시글 목록 페이지 응답 모델
class BoardPostPage {
  final List<PostSummary> posts;
  final bool hasNext;

  const BoardPostPage({
    required this.posts,
    required this.hasNext,
  });
}