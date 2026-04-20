/// 승인/거절 요청 바디 모델
class VerificationDecisionRequestModel {
  final String adminComment;

  const VerificationDecisionRequestModel({
    required this.adminComment,
  });

  Map<String, dynamic> toJson() {
    return {
      'adminComment': adminComment,
    };
  }
}