import '../../school/models/post_summary.dart';

/// 검색 화면 상태
class SearchState {
  final String keyword;
  final List<String> recentKeywords;
  final List<PostSummary> results;
  final int currentPage;
  final int pageSize;
  final bool hasNext;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isLoadingRecent;
  final bool hasSearched;
  final int? boardId;
  final String? scopeTitle;
  final String? errorMessage;

  const SearchState({
    required this.keyword,
    required this.recentKeywords,
    required this.results,
    required this.currentPage,
    required this.pageSize,
    required this.hasNext,
    required this.isLoading,
    required this.isLoadingMore,
    required this.isLoadingRecent,
    required this.hasSearched,
    required this.boardId,
    required this.scopeTitle,
    required this.errorMessage,
  });

  /// 초기 상태 생성
  factory SearchState.initial() {
    return const SearchState(
      keyword: '',
      recentKeywords: [],
      results: [],
      currentPage: 0,
      pageSize: 10,
      hasNext: false,
      isLoading: false,
      isLoadingMore: false,
      isLoadingRecent: false,
      hasSearched: false,
      boardId: null,
      scopeTitle: null,
      errorMessage: null,
    );
  }

  /// 상태 일부를 복사해서 새 상태 생성
  SearchState copyWith({
    String? keyword,
    List<String>? recentKeywords,
    List<PostSummary>? results,
    int? currentPage,
    int? pageSize,
    bool? hasNext,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isLoadingRecent,
    bool? hasSearched,
    Object? boardId = _unset,
    Object? scopeTitle = _unset,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchState(
      keyword: keyword ?? this.keyword,
      recentKeywords: recentKeywords ?? this.recentKeywords,
      results: results ?? this.results,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasNext: hasNext ?? this.hasNext,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingRecent: isLoadingRecent ?? this.isLoadingRecent,
      hasSearched: hasSearched ?? this.hasSearched,
      boardId: boardId == _unset ? this.boardId : boardId as int?,
      scopeTitle: scopeTitle == _unset
          ? this.scopeTitle
          : scopeTitle as String?,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

const Object _unset = Object();
