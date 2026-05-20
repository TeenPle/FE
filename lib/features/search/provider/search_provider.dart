import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../../school/models/board_post_page.dart';
import '../../school/models/post_summary.dart';
import '../api/search_api.dart';
import '../models/search_state.dart';
import '../services/recent_search_service.dart';

/// 검색용 공통 API 클라이언트 생성
final searchApiClientProvider = Provider<AppApiClient>((ref) {
  return AppApiClient(ref.watch(dioProvider));
});

/// 검색 API 생성
final searchApiProvider = Provider<SearchApi>((ref) {
  final client = ref.watch(searchApiClientProvider);
  return SearchApi(client: client);
});

/// 최근 검색어 저장 서비스 생성
final recentSearchServiceProvider = Provider<RecentSearchService>((ref) {
  return RecentSearchService();
});

/// 검색 상태 관리 Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchApi api;
  final RecentSearchService recentSearchService;

  SearchNotifier(this.api, this.recentSearchService)
    : super(SearchState.initial());

  /// 저장된 최근 검색어 목록을 불러옴
  Future<void> loadRecentKeywords() async {
    state = state.copyWith(isLoadingRecent: true, clearError: true);

    try {
      final recentKeywords = await recentSearchService.getRecentKeywords();

      state = state.copyWith(
        recentKeywords: recentKeywords,
        isLoadingRecent: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingRecent: false,
        errorMessage: '최근 검색어를 불러오지 못했어요.',
      );
    }
  }

  /// 검색어를 상태에 반영
  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword);
  }

  void setScope({int? boardId, String? scopeTitle}) {
    state = state.copyWith(
      boardId: boardId,
      scopeTitle: scopeTitle,
      results: const [],
      currentPage: 0,
      hasNext: false,
      hasSearched: false,
      clearError: true,
    );
  }

  /// 검색 상태를 초기 화면처럼 되돌림
  void resetSearchView() {
    state = state.copyWith(
      results: const [],
      currentPage: 0,
      hasNext: false,
      hasSearched: false,
      clearError: true,
    );
  }

  /// 최근 검색어를 눌렀을 때 검색어를 채우고 검색 수행
  Future<void> searchWithKeyword(String keyword) async {
    state = state.copyWith(keyword: keyword);
    await search();
  }

  /// 첫 페이지부터 검색 수행
  Future<void> search() async {
    final keyword = state.keyword.trim();
    if (keyword.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      results: const [],
      currentPage: 0,
      hasNext: false,
      hasSearched: true,
      clearError: true,
    );

    try {
      final BoardPostPage pageResult = await api.searchPosts(
        keyword: keyword,
        boardId: state.boardId,
        page: 0,
        size: state.pageSize,
      );

      final recentKeywords = await recentSearchService.saveKeyword(keyword);

      state = state.copyWith(
        recentKeywords: recentKeywords,
        results: _filterVisiblePosts(pageResult.posts),
        currentPage: 0,
        hasNext: pageResult.hasNext,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint('검색 실패: $e');
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(isLoading: false, errorMessage: '검색에 실패했어요.');
    }
  }

  /// 검색 결과 다음 페이지를 불러옴
  Future<void> loadMore() async {
    if (!state.hasNext) return;
    if (state.isLoading || state.isLoadingMore) return;
    if (state.keyword.trim().isEmpty) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = state.currentPage + 1;

      final BoardPostPage pageResult = await api.searchPosts(
        keyword: state.keyword.trim(),
        boardId: state.boardId,
        page: nextPage,
        size: state.pageSize,
      );

      state = state.copyWith(
        results: [...state.results, ..._filterVisiblePosts(pageResult.posts)],
        currentPage: nextPage,
        hasNext: pageResult.hasNext,
        isLoadingMore: false,
      );
    } catch (e, stackTrace) {
      debugPrint('검색 더보기 실패: $e');
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: '검색 결과를 더 불러오지 못했어요.',
      );
    }
  }

  /// 특정 최근 검색어를 삭제
  Future<void> removeRecentKeyword(String keyword) async {
    try {
      final recentKeywords = await recentSearchService.removeKeyword(keyword);

      state = state.copyWith(recentKeywords: recentKeywords);
    } catch (_) {
      state = state.copyWith(errorMessage: '최근 검색어를 삭제하지 못했어요.');
    }
  }

  /// 최근 검색어 전체를 삭제
  Future<void> clearRecentKeywords() async {
    try {
      final recentKeywords = await recentSearchService.clearAll();

      state = state.copyWith(recentKeywords: recentKeywords);
    } catch (_) {
      state = state.copyWith(errorMessage: '최근 검색어를 초기화하지 못했어요.');
    }
  }

  /// 화면에서 삭제된 게시글을 제거
  List<PostSummary> _filterVisiblePosts(List<PostSummary> posts) {
    return posts
        .where((post) => post.postStatus.toUpperCase() != 'DELETED')
        .toList();
  }
}

/// 검색 상태 provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  final api = ref.watch(searchApiProvider);
  final recentSearchService = ref.watch(recentSearchServiceProvider);

  return SearchNotifier(api, recentSearchService);
});
