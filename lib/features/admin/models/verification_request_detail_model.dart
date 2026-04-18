import 'verification_status_model.dart';

/// 학교 인증 요청 상세 모델
class VerificationRequestDetailModel {
  final int requestId;
  final String requestImageUrl;
  final VerificationStatusModel status;
  final DateTime? requestedAt;
  final int userId;
  final String userName;
  final String userEmail;
  final int schoolId;
  final String schoolName;
  final DateTime? processedAt;
  final int? processedBy;
  final String? adminComment;

  const VerificationRequestDetailModel({
    required this.requestId,
    required this.requestImageUrl,
    required this.status,
    required this.requestedAt,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.schoolId,
    required this.schoolName,
    required this.processedAt,
    required this.processedBy,
    required this.adminComment,
  });

  factory VerificationRequestDetailModel.fromJson(Map<String, dynamic> json) {
    return VerificationRequestDetailModel(
      requestId: (json['requestId'] as num).toInt(),
      requestImageUrl: json['requestImageUrl'] as String? ?? '',
      status: VerificationStatusModelX.fromJson(json['status'] as String),
      requestedAt: DateTime.tryParse(json['requestedAt'] as String? ?? ''),
      userId: (json['userId'] as num).toInt(),
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      schoolId: (json['schoolId'] as num).toInt(),
      schoolName: json['schoolName'] as String? ?? '',
      processedAt: DateTime.tryParse(json['processedAt'] as String? ?? ''),
      processedBy: json['processedBy'] == null
          ? null
          : (json['processedBy'] as num).toInt(),
      adminComment: json['adminComment'] as String?,
    );
  }
}