import '../models/school_model.dart';

/// 학교 검색 화면에서 사용하는 상태
class SignupSchoolState {
  final String keyword;
  final bool isLoading;
  final List<SchoolModel> schools;
  final String? errorMessage;

  const SignupSchoolState({
    this.keyword = '',
    this.isLoading = false,
    this.schools = const [],
    this.errorMessage,
  });

  SignupSchoolState copyWith({
    String? keyword,
    bool? isLoading,
    List<SchoolModel>? schools,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SignupSchoolState(
      keyword: keyword ?? this.keyword,
      isLoading: isLoading ?? this.isLoading,
      schools: schools ?? this.schools,
      errorMessage:
      clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}