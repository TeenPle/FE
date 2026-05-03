import '../models/board_model.dart';
import '../models/hot_filter.dart';
import '../models/post_sort_type.dart';
import '../models/post_summary.dart';

/// 학교 메인 화면 상태
class SchoolState {
  final int schoolId;
  final String schoolName;
  final String schoolDescription;
  final List<BoardModel> boards;
  final int? selectedBoardId;
  final List<PostSummary> posts;
  final List<PostSummary> hotPosts;
  final HotFilter hotFilter;
  final bool isLoadingHot;
  final PostSortType sortType;
  final int currentPage;
  final int pageSize;
  final bool hasNext;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasLoadedOnce;
  final String? errorMessage;

  const SchoolState({
    required this.schoolId,
    required this.schoolName,
    required this.schoolDescription,
    required this.boards,
    required this.selectedBoardId,
    required this.posts,
    required this.hotPosts,
    required this.hotFilter,
    required this.isLoadingHot,
    required this.sortType,
    required this.currentPage,
    required this.pageSize,
    required this.hasNext,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasLoadedOnce,
    required this.errorMessage,
  });

  factory SchoolState.initial() {
    return const SchoolState(
      schoolId: 2,
      schoolName: '',
      schoolDescription: '',
      boards: [],
      selectedBoardId: null,
      posts: [],
      hotPosts: [],
      hotFilter: HotFilter.week,
      isLoadingHot: false,
      sortType: PostSortType.latest,
      currentPage: 0,
      pageSize: 5,
      hasNext: false,
      isLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      hasLoadedOnce: false,
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
    List<PostSummary>? hotPosts,
    HotFilter? hotFilter,
    bool? isLoadingHot,
    PostSortType? sortType,
    int? currentPage,
    int? pageSize,
    bool? hasNext,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasLoadedOnce,
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
      hotPosts: hotPosts ?? this.hotPosts,
      hotFilter: hotFilter ?? this.hotFilter,
      isLoadingHot: isLoadingHot ?? this.isLoadingHot,
      sortType: sortType ?? this.sortType,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasNext: hasNext ?? this.hasNext,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
