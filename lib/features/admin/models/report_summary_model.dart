class ReportSummaryModel {
  final int reportId;
  final int reporterId;
  final String reporterNickname;
  final int reportedUserId;
  final String reportedUserNickname;
  final String targetType;
  final int targetId;
  final String reportReason;
  final String status;
  final DateTime createdAt;
  final DateTime? processedAt;

  const ReportSummaryModel({
    required this.reportId,
    required this.reporterId,
    required this.reporterNickname,
    required this.reportedUserId,
    required this.reportedUserNickname,
    required this.targetType,
    required this.targetId,
    required this.reportReason,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportSummaryModel(
      reportId: (json['reportId'] as num).toInt(),
      reporterId: (json['reporterId'] as num).toInt(),
      reporterNickname: json['reporterNickname'] as String? ?? '',
      reportedUserId: (json['reportedUserId'] as num).toInt(),
      reportedUserNickname: json['reportedUserNickname'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetId: (json['targetId'] as num).toInt(),
      reportReason: json['reportReason'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }

  String get targetTypeLabel => switch (targetType) {
    'POST' => '게시글',
    'COMMENT' => '댓글',
    'USER' => '채팅',
    _ => targetType,
  };

  String get reportReasonLabel => switch (reportReason) {
    'SPAM' => '광고·도배',
    'ABUSE' => '욕설·비방',
    'HARASSMENT' => '괴롭힘·위협',
    'OBSCENE' => '성적·음란 콘텐츠',
    'ILLEGAL' => '불법·위험 행위',
    'ETC' => '기타 운영정책 위반',
    _ => reportReason,
  };
}

class ReportDetailModel extends ReportSummaryModel {
  final int? postId;
  final String targetContent;
  final String? schoolName;
  final String? boardTitle;

  const ReportDetailModel({
    required super.reportId,
    required super.reporterId,
    required super.reporterNickname,
    required super.reportedUserId,
    required super.reportedUserNickname,
    required super.targetType,
    required super.targetId,
    this.postId,
    required this.targetContent,
    this.schoolName,
    this.boardTitle,
    required super.reportReason,
    required super.status,
    required super.createdAt,
    super.processedAt,
  });

  factory ReportDetailModel.fromJson(Map<String, dynamic> json) {
    return ReportDetailModel(
      reportId: (json['reportId'] as num).toInt(),
      reporterId: (json['reporterId'] as num).toInt(),
      reporterNickname: json['reporterNickname'] as String? ?? '',
      reportedUserId: (json['reportedUserId'] as num).toInt(),
      reportedUserNickname: json['reportedUserNickname'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetId: (json['targetId'] as num).toInt(),
      postId: json['postId'] != null ? (json['postId'] as num).toInt() : null,
      targetContent: json['targetContent'] as String? ?? '',
      schoolName: json['schoolName'] as String?,
      boardTitle: json['boardTitle'] as String?,
      reportReason: json['reportReason'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }
}
