import '../models/verification_request_list_item_model.dart';
import '../models/verification_status_model.dart';

/// 관리자 인증 요청 목록 상태
class AdminVerificationListState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final VerificationStatusModel selectedStatus;
  final List<VerificationRequestListItemModel> items;
  final String keyword;
  final String? errorMessage;

  const AdminVerificationListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.selectedStatus = VerificationStatusModel.pending,
    this.items = const [],
    this.keyword = '',
    this.errorMessage,
  });

  AdminVerificationListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    VerificationStatusModel? selectedStatus,
    List<VerificationRequestListItemModel>? items,
    String? keyword,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AdminVerificationListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      items: items ?? this.items,
      keyword: keyword ?? this.keyword,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
