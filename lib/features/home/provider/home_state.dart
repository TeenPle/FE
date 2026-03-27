import '../models/board_model.dart';
import '../models/post_summary.dart';

class HomeState {
  final String schoolName;
  final List<BoardModel> boards;
  final int selectedBoardId;
  final List<PostSummary> posts;
  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    required this.schoolName,
    required this.boards,
    required this.selectedBoardId,
    required this.posts,
    required this.isLoading,
    required this.errorMessage,
  });

  factory HomeState.initial() {
    return const HomeState(
      schoolName: '',
      boards: [],
      selectedBoardId: 0,
      posts: [],
      isLoading: false,
      errorMessage: null,
    );
  }

  HomeState copyWith({
    String? schoolName,
    List<BoardModel>? boards,
    int? selectedBoardId,
    List<PostSummary>? posts,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      schoolName: schoolName ?? this.schoolName,
      boards: boards ?? this.boards,
      selectedBoardId: selectedBoardId ?? this.selectedBoardId,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}