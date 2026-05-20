import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/admin_inquiry_api.dart';
import '../models/inquiry_model.dart';

class AdminInquiryListState {
  final List<InquirySummaryModel> inquiries;
  final String activeStatus;
  final bool isLoading;
  final String? error;

  const AdminInquiryListState({
    this.inquiries = const [],
    this.activeStatus = 'PENDING',
    this.isLoading = false,
    this.error,
  });

  AdminInquiryListState copyWith({
    List<InquirySummaryModel>? inquiries,
    String? activeStatus,
    bool? isLoading,
    String? error,
  }) {
    return AdminInquiryListState(
      inquiries: inquiries ?? this.inquiries,
      activeStatus: activeStatus ?? this.activeStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminInquiryListNotifier extends StateNotifier<AdminInquiryListState> {
  final AdminInquiryApi _api;

  AdminInquiryListNotifier(this._api) : super(const AdminInquiryListState());

  Future<void> load({String status = 'PENDING'}) async {
    state = state.copyWith(isLoading: true, activeStatus: status, error: null);
    try {
      final inquiries = await _api.getInquiries(status: status);
      state = state.copyWith(inquiries: inquiries, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '문의 목록을 불러오지 못했어요.');
    }
  }

  Future<void> refresh() => load(status: state.activeStatus);
}

final adminInquiryListProvider =
    StateNotifierProvider<AdminInquiryListNotifier, AdminInquiryListState>((
      ref,
    ) {
      return AdminInquiryListNotifier(ref.watch(adminInquiryApiProvider));
    });

class AdminInquiryDetailState {
  final InquiryDetailModel? inquiry;
  final bool isLoading;
  final bool isAnswering;
  final String? error;
  final bool answered;

  const AdminInquiryDetailState({
    this.inquiry,
    this.isLoading = false,
    this.isAnswering = false,
    this.error,
    this.answered = false,
  });

  AdminInquiryDetailState copyWith({
    InquiryDetailModel? inquiry,
    bool? isLoading,
    bool? isAnswering,
    String? error,
    bool? answered,
  }) {
    return AdminInquiryDetailState(
      inquiry: inquiry ?? this.inquiry,
      isLoading: isLoading ?? this.isLoading,
      isAnswering: isAnswering ?? this.isAnswering,
      error: error,
      answered: answered ?? this.answered,
    );
  }
}

class AdminInquiryDetailNotifier
    extends StateNotifier<AdminInquiryDetailState> {
  final AdminInquiryApi _api;
  final int inquiryId;

  AdminInquiryDetailNotifier(this._api, this.inquiryId)
    : super(const AdminInquiryDetailState());

  // 답변 화면은 최신 상태를 기준으로 재답변 가능 여부를 판단한다.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null, answered: false);
    try {
      final inquiry = await _api.getInquiry(inquiryId);
      state = state.copyWith(inquiry: inquiry, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '문의 내용을 불러오지 못했어요.');
    }
  }

  Future<void> answer(String answer) async {
    state = state.copyWith(isAnswering: true, error: null, answered: false);
    try {
      await _api.answerInquiry(inquiryId, answer);
      state = state.copyWith(isAnswering: false, answered: true);
    } catch (_) {
      state = state.copyWith(isAnswering: false, error: '답변을 등록하지 못했어요.');
    }
  }
}

final adminInquiryDetailProvider =
    StateNotifierProvider.family<
      AdminInquiryDetailNotifier,
      AdminInquiryDetailState,
      int
    >((ref, inquiryId) {
      return AdminInquiryDetailNotifier(
        ref.watch(adminInquiryApiProvider),
        inquiryId,
      );
    });
