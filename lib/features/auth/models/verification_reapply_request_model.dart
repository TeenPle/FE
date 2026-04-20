/// 학교 인증 재요청 요청 모델
class VerificationReapplyRequestModel {
  final String email;
  final String password;
  final int schoolId;

  const VerificationReapplyRequestModel({
    required this.email,
    required this.password,
    required this.schoolId,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'schoolId': schoolId,
    };
  }
}