/// 로그인 응답 DTO와 맞춘 모델
class LoginResponseModel {
  /// 로그인한 사용자 ID
  final int userId;

  /// 발급된 액세스 토큰
  final String accessToken;

  /// 사용자 권한
  /// 예: USER, ADMIN
  final String role;

  const LoginResponseModel({
    required this.userId,
    required this.accessToken,
    required this.role,
  });

  /// JSON -> 모델 변환
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      userId: (json['userId'] as num).toInt(),
      accessToken: json['accessToken'] as String,
      role: json['role'] as String,
    );
  }

  /// 관리자 여부
  bool get isAdmin => role == 'ADMIN';
}