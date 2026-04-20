/// 로그인 응답 DTO와 맞춘 모델
class LoginResponseModel {
  final int userId;
  final String accessToken;
  final String role;
  final int? schoolId;

  const LoginResponseModel({
    required this.userId,
    required this.accessToken,
    required this.role,
    this.schoolId,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      userId: (json['userId'] as num).toInt(),
      accessToken: json['accessToken'] as String,
      role: json['role'] as String,
      schoolId: json['schoolId'] != null ? (json['schoolId'] as num).toInt() : null,
    );
  }

  bool get isAdmin => role == 'ADMIN';
}