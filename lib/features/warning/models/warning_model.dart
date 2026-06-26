class UnreadWarningModel {
  final int warningId;
  final String adminComment;
  final DateTime issuedAt;
  final String? targetType; // POST | COMMENT
  final String? targetSummary; // 최대 80자 요약

  const UnreadWarningModel({
    required this.warningId,
    required this.adminComment,
    required this.issuedAt,
    this.targetType,
    this.targetSummary,
  });

  factory UnreadWarningModel.fromJson(Map<String, dynamic> json) {
    return UnreadWarningModel(
      warningId: (json['warningId'] as num).toInt(),
      adminComment: json['adminComment'] as String? ?? '',
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      targetType: json['targetType'] as String?,
      targetSummary: json['targetSummary'] as String?,
    );
  }

  String get targetTypeLabel => switch (targetType) {
    'POST' => '게시글',
    'COMMENT' => '댓글',
    _ => '',
  };
}

class WarningHistoryModel {
  final int warningId;
  final String? targetType;
  final String? targetSummary;
  final String adminComment;
  final bool isRead;
  final DateTime issuedAt;

  const WarningHistoryModel({
    required this.warningId,
    this.targetType,
    this.targetSummary,
    required this.adminComment,
    required this.isRead,
    required this.issuedAt,
  });

  factory WarningHistoryModel.fromJson(Map<String, dynamic> json) {
    return WarningHistoryModel(
      warningId: (json['warningId'] as num).toInt(),
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
