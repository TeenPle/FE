import 'verification_status_model.dart';

class VerificationRequestListItemModel {
  final int requestId;
  final VerificationStatusModel status;
  final DateTime? requestedAt;
  final int userId;
  final String userName;
  final String userEmail;
  final int schoolId;
  final String schoolName;

  const VerificationRequestListItemModel({
    required this.requestId,
    required this.status,
    required this.requestedAt,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.schoolId,
    required this.schoolName,
  });

  factory VerificationRequestListItemModel.fromJson(Map<String, dynamic> json) {
    return VerificationRequestListItemModel(
      requestId: (json['requestId'] as num).toInt(),
      status: VerificationStatusModelX.fromJson(json['status'] as String),
      requestedAt: DateTime.tryParse(json['requestedAt'] as String? ?? ''),
      userId: (json['userId'] as num).toInt(),
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      schoolId: (json['schoolId'] as num).toInt(),
      schoolName: json['schoolName'] as String? ?? '',
    );
  }
}