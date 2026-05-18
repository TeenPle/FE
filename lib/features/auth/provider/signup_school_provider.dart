import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/school_api.dart';
import 'signup_school_state.dart';

/// 학교 검색 상태를 관리하는 provider
final signupSchoolProvider =
    StateNotifierProvider<SignupSchoolNotifier, SignupSchoolState>((ref) {
      final schoolApi = ref.read(schoolApiProvider);
      return SignupSchoolNotifier(schoolApi);
    });

class SignupSchoolNotifier extends StateNotifier<SignupSchoolState> {
  final SchoolApi _schoolApi;

  SignupSchoolNotifier(this._schoolApi) : super(const SignupSchoolState());

  /// 검색어 변경
  void updateKeyword(String value) {
    state = state.copyWith(keyword: value, clearErrorMessage: true);
  }

  /// 학교 검색 API 호출
  Future<void> searchSchools(String keyword) async {
    final trimmed = keyword.trim();

    /// 검색어가 비어있으면 결과 초기화
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      schools: const [],
      clearErrorMessage: true,
    );

    try {
      final schools = await _schoolApi.searchSchools(trimmed);

      state = state.copyWith(isLoading: false, schools: schools);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        schools: const [],
        errorMessage: e.message ?? '학교 검색에 실패했습니다.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        schools: const [],
        errorMessage: '학교 검색에 실패했습니다.',
      );
    }
  }

  /// 검색 상태 초기화
  void clearSearch() {
    state = const SignupSchoolState();
  }
}
