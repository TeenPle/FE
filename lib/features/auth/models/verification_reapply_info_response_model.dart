/// 반려 사유 조회 응답 모델
class VerificationReapplyInfoResponseModel {
  final int schoolId;
  final String schoolName;
  final String adminComment;

  const VerificationReapplyInfoResponseModel({
    required this.schoolId,
    required this.schoolName,
    required this.adminComment,
  });

  factory VerificationReapplyInfoResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return VerificationReapplyInfoResponseModel(
      schoolId: (json['schoolId'] as num).toInt(),
      schoolName: json['schoolName'] as String,
      adminComment: (json['adminComment'] as String?) ?? '',
    );
  }
}