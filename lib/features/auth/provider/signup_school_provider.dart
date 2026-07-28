import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/school_api.dart';
import 'signup_school_state.dart';

final signupSchoolProvider =
    StateNotifierProvider<SignupSchoolNotifier, SignupSchoolState>((ref) {
      final schoolApi = ref.read(schoolApiProvider);
      return SignupSchoolNotifier(schoolApi);
    });

class SignupSchoolNotifier extends StateNotifier<SignupSchoolState> {
  final SchoolApi _schoolApi;
  int _requestSerial = 0;

  SignupSchoolNotifier(this._schoolApi) : super(const SignupSchoolState());

  void updateKeyword(String value) {
    state = state.copyWith(keyword: value, clearErrorMessage: true);
  }

  Future<void> searchSchools(String keyword) async {
    final trimmed = keyword.trim();
    final requestSerial = ++_requestSerial;

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
      if (!mounted || requestSerial != _requestSerial) return;

      state = state.copyWith(isLoading: false, schools: schools);
    } on DioException catch (e) {
      if (!mounted || requestSerial != _requestSerial) return;

      state = state.copyWith(
        isLoading: false,
        schools: const [],
        errorMessage: e.message ?? '학교 검색에 실패했어요.',
      );
    } catch (_) {
      if (!mounted || requestSerial != _requestSerial) return;

      state = state.copyWith(
        isLoading: false,
        schools: const [],
        errorMessage: '학교 검색에 실패했어요.',
      );
    }
  }

  void clearSearch() {
    _requestSerial++;
    state = const SignupSchoolState();
  }
}
