import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/school_repository.dart';
import '../models/board_model.dart';
import '../models/post_sort_type.dart';
import '../models/post_summary.dart';
import 'school_state.dart';

/// 학교 메인 화면 상태 관리 Notifier
class SchoolNotifier extends StateNotifier<SchoolState> {
  final SchoolRepository repository;

  SchoolNotifier(this.repository) : super(SchoolState.initial());

  /// 최초 학교 정보와 기본 게시판 목록을 불러옴
  Future<void> loadInitialSchool(int schoolId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await repository.getSchoolDetail(
        schoolId: schoolId,
        page: 0,
        size: state.pageSize,
      );

      final defaultBoard = _findDefaultBoard(result.boards);

      state = state.copyWith(
        schoolId: result.schoolId,
        schoolName: result.name,
        schoolDescription: result.description,
        boards: result.boards,
        selectedBoardId: defaultBoard?.id,
        posts: _filterVisiblePosts(result.posts),
        sortType: PostSortType.latest,
        currentPage: 0,
        hasNext: result.hasNext,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasLoadedOnce: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: '학교 정보를 불러오지 못했습니다.',
      );
    }
  }

  /// 게시판을 바꾸면 첫 페이지부터 새로 조회
  Future<void> selectBoard(int boardId) async {
    if (state.selectedBoardId == boardId) return;

    state = state.copyWith(
      selectedBoardId: boardId,
      posts: const [],
      currentPage: 0,
      hasNext: false,
      isLoading: true,
      clearError: true,
    );

    await _loadBoardFirstPage(boardId: boardId);
  }

  /// 정렬 기준을 바꾸면 현재 게시판을 첫 페이지부터 다시 조회
  Future<void> changeSortType(PostSortType sortType) async {
    if (state.sortType == sortType) return;
    if (state.selectedBoardId == null) return;

    state = state.copyWith(
      sortType: sortType,
      posts: const [],
      currentPage: 0,
      hasNext: false,
      isLoading: true,
      clearError: true,
    );

    await _loadBoardFirstPage(boardId: state.selectedBoardId!);
  }

  /// 당겨서 새로고침 시 현재 게시판 첫 페이지를 다시 불러옴
  Future<void> refreshPosts() async {
    if (state.selectedBoardId == null) return;

    state = state.copyWith(
      isRefreshing: true,
      clearError: true,
    );

    try {
      final pageResult = await repository.getPostsByBoard(
        boardId: state.selectedBoardId!,
        sortType: state.sortType,
        page: 0,
        size: state.pageSize,
      );

      state = state.copyWith(
        posts: _filterVisiblePosts(pageResult.posts),
        currentPage: 0,
        hasNext: pageResult.hasNext,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasLoadedOnce: true,
      );
    } catch (_) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: '게시글 목록을 새로고침하지 못했습니다.',
      );
    }
  }

  /// 다음 페이지 게시글을 이어서 불러옴
  Future<void> loadMorePosts() async {
    if (state.selectedBoardId == null) return;
    if (!state.hasNext) return;
    if (state.isLoadingMore || state.isLoading || state.isRefreshing) return;

    state = state.copyWith(
      isLoadingMore: true,
      clearError: true,
    );

    try {
      final nextPage = state.currentPage + 1;

      final pageResult = await repository.getPostsByBoard(
        boardId: state.selectedBoardId!,
        sortType: state.sortType,
        page: nextPage,
        size: state.pageSize,
      );

      state = state.copyWith(
        posts: [
          ...state.posts,
          ..._filterVisiblePosts(pageResult.posts),
        ],
        currentPage: nextPage,
        hasNext: pageResult.hasNext,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: '추가 게시글을 불러오지 못했습니다.',
      );
    }
  }

  /// 글 작성 후 현재 게시판 목록을 다시 불러옴
  Future<void> reloadCurrentBoard() async {
    if (state.selectedBoardId == null) return;
    await refreshPosts();
  }

  /// 첫 페이지 조회를 공통 처리
  Future<void> _loadBoardFirstPage({
    required int boardId,
  }) async {
    try {
      final pageResult = await repository.getPostsByBoard(
        boardId: boardId,
        sortType: state.sortType,
        page: 0,
        size: state.pageSize,
      );

      state = state.copyWith(
        posts: _filterVisiblePosts(pageResult.posts),
        currentPage: 0,
        hasNext: pageResult.hasNext,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasLoadedOnce: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: '게시글 목록을 불러오지 못했습니다.',
      );
    }
  }

  /// 목록에서 삭제된 게시글을 제거
  List<PostSummary> _filterVisiblePosts(List<PostSummary> posts) {
    return posts
        .where((post) => post.postStatus.toUpperCase() != 'DELETED')
        .toList();
  }

  /// 기본 게시판을 우선적으로 선택
  BoardModel? _findDefaultBoard(List<BoardModel> boards) {
    try {
      return boards.firstWhere((b) => b.title == '자유게시판');
    } catch (_) {
      return boards.isNotEmpty ? boards.first : null;
    }
  }
}