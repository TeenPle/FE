import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/inquiry_api.dart';
import '../models/inquiry_model.dart';

class InquiryListState {
  final List<InquirySummaryModel> inquiries;
  final bool isLoading;
  final String? error;

  const InquiryListState({
    this.inquiries = const [],
    this.isLoading = false,
    this.error,
  });

  InquiryListState copyWith({
    List<InquirySummaryModel>? inquiries,
    bool? isLoading,
    String? error,
  }) {
    return InquiryListState(
      inquiries: inquiries ?? this.inquiries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InquiryListNotifier extends StateNotifier<InquiryListState> {
  final InquiryApi _api;

  InquiryListNotifier(this._api) : super(const InquiryListState());

  // 문의 홈 진입과 새 문의 등록 후 갱신에 함께 사용한다.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final inquiries = await _api.getMyInquiries();
      state = state.copyWith(inquiries: inquiries, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '문의 내역을 불러오지 못했습니다.');
    }
  }
}

final inquiryListProvider =
    StateNotifierProvider<InquiryListNotifier, InquiryListState>((ref) {
      return InquiryListNotifier(ref.watch(inquiryApiProvider));
    });

class InquiryDetailState {
  final InquiryDetailModel? inquiry;
  final bool isLoading;
  final String? error;

  const InquiryDetailState({this.inquiry, this.isLoading = false, this.error});

  InquiryDetailState copyWith({
    InquiryDetailModel? inquiry,
    bool? isLoading,
    String? error,
  }) {
    return InquiryDetailState(
      inquiry: inquiry ?? this.inquiry,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InquiryDetailNotifier extends StateNotifier<InquiryDetailState> {
  final InquiryApi _api;
  final int inquiryId;

  InquiryDetailNotifier(this._api, this.inquiryId)
    : super(const InquiryDetailState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final inquiry = await _api.getMyInquiry(inquiryId);
      state = state.copyWith(inquiry: inquiry, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '문의 내용을 불러오지 못했습니다.');
    }
  }
}

final inquiryDetailProvider =
    StateNotifierProvider.family<
      InquiryDetailNotifier,
      InquiryDetailState,
      int
    >((ref, inquiryId) {
      return InquiryDetailNotifier(ref.watch(inquiryApiProvider), inquiryId);
    });

class InquiryCreateState {
  final bool isSubmitting;
  final String? error;
  final bool submitted;

  const InquiryCreateState({
    this.isSubmitting = false,
    this.error,
    this.submitted = false,
  });

  InquiryCreateState copyWith({
    bool? isSubmitting,
    String? error,
    bool? submitted,
  }) {
    return InquiryCreateState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      submitted: submitted ?? this.submitted,
    );
  }
}

class InquiryCreateNotifier extends StateNotifier<InquiryCreateState> {
  final InquiryApi _api;

  InquiryCreateNotifier(this._api) : super(const InquiryCreateState());

  // 사용자가 입력하는 값은 제목과 내용만 유지해 문의 진입 장벽을 낮춘다.
  Future<void> submit({required String title, required String content}) async {
    state = state.copyWith(isSubmitting: true, error: null, submitted: false);
    try {
      await _api.createInquiry(title: title, content: content);
      state = state.copyWith(isSubmitting: false, submitted: true);
    } catch (_) {
      state = state.copyWith(isSubmitting: false, error: '문의를 접수하지 못했습니다.');
    }
  }

  void clearResult() {
    state = const InquiryCreateState();
  }
}

final inquiryCreateProvider =
    StateNotifierProvider<InquiryCreateNotifier, InquiryCreateState>((ref) {
      return InquiryCreateNotifier(ref.watch(inquiryApiProvider));
    });
