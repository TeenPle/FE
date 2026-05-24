import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/school_model.dart';
import 'signup_form_state.dart';
import 'signup_secret_store.dart';

/// 회원가입 전체 폼 상태를 관리하는 provider
final signupFormProvider =
    StateNotifierProvider<SignupFormNotifier, SignupFormState>((ref) {
      return SignupFormNotifier();
    });

class SignupFormNotifier extends StateNotifier<SignupFormState> {
  SignupFormNotifier() : super(const SignupFormState());

  /// 학교 선택 상태 저장
  void updateSelectedSchool(SchoolModel school) {
    state = state.copyWith(selectedSchool: school);
  }

  /// 학년 저장
  void updateGrade(int grade) {
    state = state.copyWith(grade: grade);
  }

  /// 이름 저장
  void updateUsername(String value) {
    state = state.copyWith(username: value);
  }

  /// 닉네임 저장
  void updateNickname(String value) {
    state = state.copyWith(nickname: value);
  }

  /// 성별 저장
  /// MALE / FEMALE 값을 저장
  void updateGender(String value) {
    state = state.copyWith(gender: value);
  }

  /// 이메일 저장
  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  /// 이메일 인증 토큰 저장
  void updateVerificationToken(String token) {
    state = state.copyWith(verificationToken: token);
  }

  /// 휴대폰 번호 저장
  void updatePhoneNumber(String value) {
    state = state.copyWith(phoneNumber: value);
  }

  /// 학생증 파일 경로 저장
  void updateStudentCardFilePath(String value) {
    state = state.copyWith(studentCardFilePath: value);
  }

  /// 회원가입 입력값 전체 초기화
  void clear() {
    SignupSecretStore.clear();
    state = const SignupFormState();
  }
}
