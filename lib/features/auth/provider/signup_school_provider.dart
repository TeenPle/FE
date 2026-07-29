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

  /// 입력값이 바뀌는 즉시 진행 중인 검색 응답을 무효화한다.
  ///
  /// 디바운스가 끝날 때까지 이전 검색 결과를 남겨두면, 예를 들어
  /// `오`의 응답이 `오남`을 입력한 뒤 도착해 다른 학교가 잠시 보일 수 있다.
  /// 따라서 새 API 요청을 보내기 전이라도 기존 목록과 로딩 상태를 정리한다.
  void updateKeyword(String value) {
    _requestSerial++;
    state = state.copyWith(
      keyword: value,
      isLoading: false,
      schools: const [],
      clearErrorMessage: true,
    );
  }

  /// 검색 결과에서 학교를 선택했을 때 입력창의 키워드만 동기화한다.
  ///
  /// 선택 직전의 검색 결과는 유지해야 선택 표시를 보여줄 수 있지만,
  /// 아직 진행 중인 과거 요청은 선택 결과를 덮어쓰지 못하도록 무효화한다.
  void selectSchoolName(String schoolName) {
    _requestSerial++;
    state = state.copyWith(
      keyword: schoolName,
      isLoading: false,
      clearErrorMessage: true,
    );
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
