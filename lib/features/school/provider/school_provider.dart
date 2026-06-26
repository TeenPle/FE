import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/school_repository.dart';
import '../models/board_post_page.dart';
import '../models/hot_filter.dart';
import '../models/post_sort_type.dart';
import '../models/post_summary.dart';
import '../models/school_response.dart';
import 'school_state.dart';

/// 학교 메인 화면 상태 관리 Notifier
class SchoolNotifier extends StateNotifier<SchoolState> {
  final SchoolRepository repository;

  SchoolNotifier(this.repository) : super(SchoolState.initial());

  /// 최초 학교 정보와 전체 게시판 최신글을 병렬로 불러옴 (전체 탭으로 시작)
  Future<void> loadInitialSchool(int schoolId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      late final SchoolResponse detail;
      late final BoardPostPage allPosts;
      late final List<PostSummary> topRecommendedPosts;

      await Future.wait([
        repository.getSchoolDetail(schoolId: schoolId).then((v) => detail = v),
        repository
            .getAllPostsBySchool(
              schoolId: schoolId,
              page: 0,
              size: state.pageSize,
            )
            .then((v) => allPosts = v),
        repository
            .getTopRecommendedPosts(schoolId: schoolId, hours: 3, size: 3)
            .then((v) => topRecommendedPosts = v),
      ]);

      state = state.copyWith(
        schoolId: detail.schoolId,
        schoolName: detail.name,
        schoolDescription: detail.description,
        boards: detail.boards,
        clearSelectedBoard: true,
        posts: _filterVisiblePosts(allPosts.posts),
        topRecommendedPosts: _filterVisiblePosts(topRecommendedPosts),
        sortType: PostSortType.latest,
        currentPage: 0,
        hasNext: allPosts.hasNext,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasLoadedOnce: true,
      );

      loadHotPosts();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: '학교 정보를 불러오지 못했어요.',
      );
    }
  }

  /// 전체 탭 선택
  Future<void> selectAllBoards() async {
    if (state.selectedBoardId == null) return;

    state = state.copyWith(
      clearSelectedBoard: true,
      posts: const [],
      currentPage: 0,
      hasNext: false,
      isLoading: true,
      clearError: true,
    );

    await _loadAllBoardsFirstPage();
  }

  /// 특정 게시판 탭 선택 시 해당 게시판 첫 페이지부터 조회
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

  /// 정렬 기준을 바꾸면 현재 게시판을 첫 페이지부터 다시 조회 (전체 탭에서는 무시)
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

  /// 당겨서 새로고침 — 전체 탭 / 개별 게시판 모두 지원
  Future<void> refreshPosts() async {
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final BoardPostPage pageResult;
      final List<PostSummary> topRecommendedPosts;
      if (state.selectedBoardId == null) {
        final results = await Future.wait([
          repository.getAllPostsBySchool(
            schoolId: state.schoolId,
            page: 0,
            size: state.pageSize,
          ),
          repository.getTopRecommendedPosts(
            schoolId: state.schoolId,
            hours: 3,
            size: 3,
          ),
        ]);
        pageResult = results[0] as BoardPostPage;
        topRecommendedPosts = results[1] as List<PostSummary>;
      } else {
        pageResult = await repository.getPostsByBoard(
          boardId: state.selectedBoardId!,
          sortType: state.sortType,
          page: 0,
          size: state.pageSize,
        );
        topRecommendedPosts = state.topRecommendedPosts;
      }

      state = state.copyWith(
        posts: _filterVisiblePosts(pageResult.posts),
        topRecommendedPosts: state.selectedBoardId == null
            ? _filterVisiblePosts(topRecommendedPosts)
            : topRecommendedPosts,
        currentPage: 0,
        hasNext: pageResult.hasNext,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasLoadedOnce: true,
      );

      loadHotPosts();
    } catch (_) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: '게시글 목록을 새로고침하지 못했어요.',
      );
    }
  }

  /// 다음 페이지 게시글을 이어서 불러옴 — 전체 탭 / 개별 게시판 모두 지원
  Future<void> loadMorePosts() async {
    if (!state.hasNext) return;
    if (state.isLoadingMore || state.isLoading || state.isRefreshing) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = state.currentPage + 1;
      final BoardPostPage pageResult;

      if (state.selectedBoardId == null) {
        pageResult = await repository.getAllPostsBySchool(
          schoolId: state.schoolId,
          page: nextPage,
          size: state.pageSize,
        );
      } else {
        pageResult = await repository.getPostsByBoard(
          boardId: state.selectedBoardId!,
          sortType: state.sortType,
          page: nextPage,
          size: state.pageSize,
        );
      }

      state = state.copyWith(
        posts: [...state.posts, ..._filterVisiblePosts(pageResult.posts)],
        currentPage: nextPage,
        hasNext: pageResult.hasNext,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: '추가 게시글을 불러오지 못했어요.',
      );
    }
  }

  /// 글 작성 후 현재 탭(전체 또는 개별 게시판) 목록을 다시 불러옴
  Future<void> reloadCurrentBoard() async {
    await refreshPosts();
  }

  /// API 호출 없이 특정 게시글의 댓글 수를 로컬에서 업데이트
  void updatePostCommentCount(int postId, int commentCount) {
    state = state.copyWith(
      posts: state.posts
          .map(
            (p) => p.id == postId ? p.copyWith(commentCount: commentCount) : p,
          )
          .toList(),
      hotPosts: state.hotPosts
          .map(
            (p) => p.id == postId ? p.copyWith(commentCount: commentCount) : p,
          )
          .toList(),
      topRecommendedPosts: state.topRecommendedPosts
          .map(
            (p) => p.id == postId ? p.copyWith(commentCount: commentCount) : p,
          )
          .toList(),
    );
  }

  /// HOT 게시글을 현재 필터 기준으로 조회
  Future<void> loadHotPosts() async {
    if (state.isLoadingHot) return;

    state = state.copyWith(isLoadingHot: true, clearError: true);

    try {
      final posts = await repository.getHotPosts(
        schoolId: state.schoolId,
        filter: state.hotFilter,
        size: 20,
      );
      state = state.copyWith(
        hotPosts: _filterVisiblePosts(posts),
        isLoadingHot: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingHot: false,
        errorMessage: 'HOT 게시글을 불러오지 못했어요.',
      );
    }
  }

  Future<void> loadTopRecommendedPosts() async {
    if (state.schoolId <= 0) return;

    try {
      final posts = await repository.getTopRecommendedPosts(
        schoolId: state.schoolId,
        hours: 3,
        size: 3,
      );
      state = state.copyWith(
        topRecommendedPosts: _filterVisiblePosts(posts),
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(errorMessage: 'HOT 피드를 불러오지 못했어요.');
    }
  }

  /// HOT 필터 변경 후 재조회
  Future<void> changeHotFilter(HotFilter filter) async {
    if (state.hotFilter == filter) return;
    state = state.copyWith(hotFilter: filter, hotPosts: const []);
    await loadHotPosts();
  }

  /// 전체 게시판 첫 페이지 조회 공통 처리
  Future<void> _loadAllBoardsFirstPage() async {
    try {
      final pageResult = await repository.getAllPostsBySchool(
        schoolId: state.schoolId,
        page: 0,
        size: state.pageSize,
      );

      state = state.copyWith(
        posts: _filterVisiblePosts(pageResult.posts),
        topRecommendedPosts: _filterVisiblePosts(
          await repository.getTopRecommendedPosts(
            schoolId: state.schoolId,
            hours: 3,
            size: 3,
          ),
        ),
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
        errorMessage: '게시글 목록을 불러오지 못했어요.',
      );
    }
  }

  /// 특정 게시판 첫 페이지 조회 공통 처리
  Future<void> _loadBoardFirstPage({required int boardId}) async {
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
        errorMessage: '게시글 목록을 불러오지 못했어요.',
      );
    }
  }

  /// 목록에서 삭제된 게시글을 제거
  List<PostSummary> _filterVisiblePosts(List<PostSummary> posts) {
    return posts
        .where((post) => post.postStatus.toUpperCase() != 'DELETED')
        .toList();
  }
}
