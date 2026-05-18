/// 로그인 요청 DTO와 맞춘 모델
class LoginRequestModel {
  /// 로그인 이메일
  final String email;

  /// 로그인 비밀번호
  final String password;

  const LoginRequestModel({required this.email, required this.password});

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
