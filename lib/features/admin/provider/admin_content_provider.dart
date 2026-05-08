import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_content_api.dart';
import '../models/admin_content_model.dart';

class AdminSchoolListState {
  final List<AdminSchoolModel> schools;
  final String keyword;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const AdminSchoolListState({
    this.schools = const [],
    this.keyword = '',
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  AdminSchoolListState copyWith({
    List<AdminSchoolModel>? schools,
    String? keyword,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return AdminSchoolListState(
      schools: schools ?? this.schools,
      keyword: keyword ?? this.keyword,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class AdminSchoolListNotifier extends StateNotifier<AdminSchoolListState> {
  final AdminContentApi _api;

  AdminSchoolListNotifier(this._api) : super(const AdminSchoolListState());

  Future<void> load({String keyword = ''}) async {
    state = state.copyWith(
      keyword: keyword,
      page: 0,
      isLoading: true,
      hasMore: true,
      error: null,
    );
    try {
      final schools = await _api.searchSchools(keyword: keyword);
      state = state.copyWith(
        schools: schools,
        isLoading: false,
        hasMore: schools.length == 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '학교 목록을 불러오지 못했습니다.');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final more = await _api.searchSchools(keyword: state.keyword, page: nextPage);
      state = state.copyWith(
        schools: [...state.schools, ...more],
        page: nextPage,
        isLoadingMore: false,
        hasMore: more.length == 20,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false, error: '추가 학교 목록을 불러오지 못했습니다.');
    }
  }
}

final adminSchoolListProvider =
    StateNotifierProvider<AdminSchoolListNotifier, AdminSchoolListState>((ref) {
  return AdminSchoolListNotifier(ref.watch(adminContentApiProvider));
});

class AdminBoardListState {
  final List<AdminBoardModel> boards;
  final bool isLoading;
  final String? error;

  const AdminBoardListState({
    this.boards = const [],
    this.isLoading = false,
    this.error,
  });

  AdminBoardListState copyWith({
    List<AdminBoardModel>? boards,
    bool? isLoading,
    String? error,
  }) {
    return AdminBoardListState(
      boards: boards ?? this.boards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminBoardListNotifier extends StateNotifier<AdminBoardListState> {
  final AdminContentApi _api;
  final int schoolId;

  AdminBoardListNotifier(this._api, this.schoolId)
      : super(const AdminBoardListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final boards = await _api.getBoardsBySchool(schoolId);
      state = state.copyWith(boards: boards, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '게시판 목록을 불러오지 못했습니다.');
    }
  }
}

final adminBoardListProvider = StateNotifierProvider.family<
    AdminBoardListNotifier, AdminBoardListState, int>((ref, schoolId) {
  return AdminBoardListNotifier(ref.watch(adminContentApiProvider), schoolId);
});

class AdminPostListState {
  final List<AdminPostSummaryModel> posts;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const AdminPostListState({
    this.posts = const [],
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  AdminPostListState copyWith({
    List<AdminPostSummaryModel>? posts,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return AdminPostListState(
      posts: posts ?? this.posts,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class AdminPostListNotifier extends StateNotifier<AdminPostListState> {
  final AdminContentApi _api;
  final int boardId;

  AdminPostListNotifier(this._api, this.boardId)
      : super(const AdminPostListState());

  Future<void> load() async {
    state = state.copyWith(page: 0, isLoading: true, hasMore: true, error: null);
    try {
      final posts = await _api.getPostsByBoard(boardId: boardId);
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '게시글 목록을 불러오지 못했습니다.');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final more = await _api.getPostsByBoard(boardId: boardId, page: nextPage);
      state = state.copyWith(
        posts: [...state.posts, ...more],
        page: nextPage,
        isLoadingMore: false,
        hasMore: more.length == 20,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false, error: '추가 게시글을 불러오지 못했습니다.');
    }
  }
}

final adminPostListProvider = StateNotifierProvider.family<
    AdminPostListNotifier, AdminPostListState, int>((ref, boardId) {
  return AdminPostListNotifier(ref.watch(adminContentApiProvider), boardId);
});

class AdminPostDetailState {
  final AdminPostDetailModel? post;
  final bool isLoading;
  final String? error;

  const AdminPostDetailState({
    this.post,
    this.isLoading = false,
    this.error,
  });

  AdminPostDetailState copyWith({
    AdminPostDetailModel? post,
    bool? isLoading,
    String? error,
  }) {
    return AdminPostDetailState(
      post: post ?? this.post,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminPostDetailNotifier extends StateNotifier<AdminPostDetailState> {
  final AdminContentApi _api;
  final int postId;

  AdminPostDetailNotifier(this._api, this.postId)
      : super(const AdminPostDetailState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final post = await _api.getPostDetail(postId);
      state = state.copyWith(post: post, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '게시글 상세를 불러오지 못했습니다.');
    }
  }
}

final adminPostDetailProvider = StateNotifierProvider.family<
    AdminPostDetailNotifier, AdminPostDetailState, int>((ref, postId) {
  return AdminPostDetailNotifier(ref.watch(adminContentApiProvider), postId);
});
