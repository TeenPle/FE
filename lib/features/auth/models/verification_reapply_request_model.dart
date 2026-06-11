/// 학교 인증 재요청 요청 모델
class VerificationReapplyRequestModel {
  final String email;
  final String password;
  final int schoolId;

  // FCM 푸시 토큰 (선택). 재신청도 로그인 없이 진행되므로
  // 앱 재설치 등으로 바뀐 토큰을 함께 보내 인증 결과 푸시를 받을 수 있게 한다.
  final String? fcmToken;
  final String? fcmPlatform;

  const VerificationReapplyRequestModel({
    required this.email,
    required this.password,
    required this.schoolId,
    this.fcmToken,
    this.fcmPlatform,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'schoolId': schoolId,
      if (fcmToken != null && fcmPlatform != null) ...{
        'fcmToken': fcmToken,
        'fcmPlatform': fcmPlatform,
      },
    };
  }
}
