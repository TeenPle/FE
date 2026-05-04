class AdminWarningHistoryModel {
  final int warningId;
  final int userId;
  final String userNickname;
  final int? reportId;
  final String? targetType;
  final String? targetSummary;
  final String adminComment;
  final bool isRead;
  final DateTime issuedAt;

  const AdminWarningHistoryModel({
    required this.warningId,
    required this.userId,
    required this.userNickname,
    this.reportId,
    this.targetType,
    this.targetSummary,
    required this.adminComment,
    required this.isRead,
    required this.issuedAt,
  });

  factory AdminWarningHistoryModel.fromJson(Map<String, dynamic> json) {
    return AdminWarningHistoryModel(
      warningId: (json['warningId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userNickname: json['userNickname'] as String? ?? '',
      reportId: (json['reportId'] as num?)?.toInt(),
      targetType: json['targetType'] as String?,
      targetSummary: json['targetSummary'] as String?,
      adminComment: json['adminComment'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
    );
  }

  String get targetTypeLabel => switch (targetType) {
        'POST' => '게시글',
        'COMMENT' => '댓글',
        _ => '',
      };
}
