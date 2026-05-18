import '../models/school_model.dart';

/// 회원가입 전체 입력값을 관리하는 상태
class SignupFormState {
  /// 사용자가 선택한 학교 정보
  final SchoolModel? selectedSchool;

  /// 사용자가 선택한 학년
  /// 프론트에서는 1, 2, 3 숫자로 들고 있다가
  /// 회원가입 API 호출 시 FIRST, SECOND, THIRD로 변환해서 보냄
  final int? grade;

  /// 사용자가 입력한 이름
  final String username;

  /// 사용자가 입력한 닉네임
  final String nickname;

  /// 사용자가 선택한 성별
  /// 백엔드 enum 값에 맞게 MALE / FEMALE 사용
  final String gender;

  /// 사용자가 입력한 이메일
  final String email;

  /// 이메일 인증 성공 후 내려오는 토큰
  final String verificationToken;

  /// 사용자가 입력한 비밀번호
  final String password;

  /// 사용자가 입력한 비밀번호 확인값
  final String passwordConfirm;

  /// 사용자가 입력한 휴대폰 번호
  final String phoneNumber;

  /// 사용자가 선택한 학생증 이미지 파일 경로
  final String studentCardFilePath;

  const SignupFormState({
    this.selectedSchool,
    this.grade,
    this.username = '',
    this.nickname = '',
    this.gender = '',
    this.email = '',
    this.verificationToken = '',
    this.password = '',
    this.passwordConfirm = '',
    this.phoneNumber = '',
    this.studentCardFilePath = '',
  });

  SignupFormState copyWith({
    SchoolModel? selectedSchool,
    int? grade,
    String? username,
    String? nickname,
    String? gender,
    String? email,
    String? verificationToken,
    String? password,
    String? passwordConfirm,
    String? phoneNumber,
    String? studentCardFilePath,
    bool clearSelectedSchool = false,
  }) {
    return SignupFormState(
      selectedSchool: clearSelectedSchool
          ? null
          : (selectedSchool ?? this.selectedSchool),
      grade: grade ?? this.grade,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      verificationToken: verificationToken ?? this.verificationToken,
      password: password ?? this.password,
      passwordConfirm: passwordConfirm ?? this.passwordConfirm,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      studentCardFilePath: studentCardFilePath ?? this.studentCardFilePath,
    );
  }
}
