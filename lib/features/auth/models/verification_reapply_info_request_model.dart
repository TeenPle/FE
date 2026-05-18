/// 반려 사유 조회 요청 모델
class VerificationReapplyInfoRequestModel {
  final String email;
  final String password;

  const VerificationReapplyInfoRequestModel({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
