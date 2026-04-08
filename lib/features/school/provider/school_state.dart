import '../models/board_model.dart';
import '../models/post_summary.dart';

class SchoolState {
  final int schoolId;
  final String schoolName;
  final String schoolDescription;
  final List<BoardModel> boards;
  final int? selectedBoardId;
  final List<PostSummary> posts;
  final bool hasNext;
  final bool isLoading;
  final String? errorMessage;

  const SchoolState({
    required this.schoolId,
    required this.schoolName,
    required this.schoolDescription,
    required this.boards,
    required this.selectedBoardId,
    required this.posts,
    required this.hasNext,
    required this.isLoading,
    required this.errorMessage,
  });

  factory SchoolState.initial() {
    return const SchoolState(
      schoolId: 1,
      schoolName: '',
      schoolDescription: '',
      boards: [],
      selectedBoardId: null,
      posts: [],
      hasNext: false,
      isLoading: false,
      errorMessage: null,
    );
  }

  SchoolState copyWith({
    int? schoolId,
    String? schoolName,
    String? schoolDescription,
    List<BoardModel>? boards,
    int? selectedBoardId,
    List<PostSummary>? posts,
    bool? hasNext,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SchoolState(
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      schoolDescription: schoolDescription ?? this.schoolDescription,
      boards: boards ?? this.boards,
      selectedBoardId: selectedBoardId ?? this.selectedBoardId,
      posts: posts ?? this.posts,
      hasNext: hasNext ?? this.hasNext,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}