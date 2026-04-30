import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/school_repository.dart';
import '../models/board_model.dart';
import '../models/board_post_page.dart';
import '../models/post_sort_type.dart';
import '../models/post_summary.dart';
import '../models/school_response.dart';
import 'school_state.dart';

/// 학교 메인 화면 상태 관리 Notifier
class SchoolNotifier extends StateNotifier<SchoolState> {
  final SchoolRepository repository;

  SchoolNotifier(this.repository) : super(SchoolState.initial());

  /// 최초 학교 정보와 기본 게시판 목록을 불러옴
  Future<void> loadInitialSchool(int schoolId) async {
    state = state.copyWith(
      isLoading: true,
      isHotLoading: true,
      clearError: true,
    );

    // 학교 상세 + 인기글 두 요청을 동시에 시작, 각각 독립적으로 에러 처리
    final results = await Future.wait([
      repository
          .getSchoolDetail(schoolId: schoolId, page: 0, size: state.pageSize)
          .then<Object?>((v) => v)
          .catchError((e) => e),
      repository
          .getHotPosts(schoolId: schoolId)
          .then<Object?>((v) => v)
          .catchError((e) => e),
    ]);

    final schoolResult = results[0];
    final hotResult = results[1];

    if (schoolResult is! SchoolResponse) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        isHotLoading: false,
        errorMessage: '학교 정보를 불러오지 못했습니다.',
      );
      return;
    }

    final defaultBoard = _findDefaultBoard(schoolResult.boards);

    final hotPosts = hotResult is List<PostSummary> ? hotResult : <PostSummary>[];

    state = state.copyWith(
      schoolId: schoolResult.schoolId,
      schoolName: schoolResult.name,
      schoolDescription: schoolResult.description,
      boards: schoolResult.boards,
      selectedBoardId: defaultBoard?.id,
      posts: _filterVisiblePosts(schoolResult.posts),
      hotPosts: _filterVisiblePosts(hotPosts),
      sortType: PostSortType.latest,
      currentPage: 0,
      hasNext: schoolResult.hasNext,
      isLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      isHotLoading: false,
      hasLoadedOnce: true,
    );
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

  /// 당겨서 새로고침 시 현재 게시판 첫 페이지와 인기글을 함께 새로고침
  Future<void> refreshPosts() async {
    if (state.selectedBoardId == null) return;

    state = state.copyWith(
      isRefreshing: true,
      isHotLoading: true,
      clearError: true,
    );

    // 게시판 글 + 인기글 두 요청 동시에 시작, 각각 독립적으로 에러 처리
    final results = await Future.wait([
      repository
          .getPostsByBoard(
            boardId: state.selectedBoardId!,
            sortType: state.sortType,
            page: 0,
            size: state.pageSize,
          )
          .then<Object?>((v) => v)
          .catchError((e) => e),
      repository
          .getHotPosts(schoolId: state.schoolId)
          .then<Object?>((v) => v)
          .catchError((e) => e),
    ]);

    final boardResult = results[0];
    final hotResult = results[1];

    if (boardResult is! BoardPostPage) {
      state = state.copyWith(
        isRefreshing: false,
        isHotLoading: false,
        errorMessage: '게시글 목록을 새로고침하지 못했습니다.',
      );
      return;
    }

    final hotPosts = hotResult is List<PostSummary> ? hotResult : <PostSummary>[];

    state = state.copyWith(
      posts: _filterVisiblePosts(boardResult.posts),
      hotPosts: _filterVisiblePosts(hotPosts),
      currentPage: 0,
      hasNext: boardResult.hasNext,
      isLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      isHotLoading: false,
      hasLoadedOnce: true,
    );
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