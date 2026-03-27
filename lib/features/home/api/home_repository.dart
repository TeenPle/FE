import '../models/board_model.dart';
import '../models/post_summary.dart';

class HomeInitialResult {
  final String schoolName;
  final List<BoardModel> boards;
  final int defaultBoardId;
  final List<PostSummary> posts;

  const HomeInitialResult({
    required this.schoolName,
    required this.boards,
    required this.defaultBoardId,
    required this.posts,
  });
}

abstract class HomeRepository {
  Future<HomeInitialResult> loadInitialHome();
  Future<List<PostSummary>> getPostsByBoard(int boardId);
}