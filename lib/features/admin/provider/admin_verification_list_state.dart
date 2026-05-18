import '../models/verification_request_list_item_model.dart';
import '../models/verification_status_model.dart';

/// 관리자 인증 요청 목록 상태
class AdminVerificationListState {
  final bool isLoading;
  final VerificationStatusModel selectedStatus;
  final List<VerificationRequestListItemModel> items;
  final String? errorMessage;

  const AdminVerificationListState({
    this.isLoading = false,
    this.selectedStatus = VerificationStatusModel.pending,
    this.items = const [],
    this.errorMessage,
  });

  AdminVerificationListState copyWith({
    bool? isLoading,
    VerificationStatusModel? selectedStatus,
    List<VerificationRequestListItemModel>? items,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AdminVerificationListState(
      isLoading: isLoading ?? this.isLoading,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      items: items ?? this.items,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
