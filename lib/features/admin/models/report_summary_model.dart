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
        _ => targetType,
      };

  String get reportReasonLabel => switch (reportReason) {
        'SPAM' => '스팸',
        'ABUSE' => '욕설/모욕',
        'OBSCENE' => '음란물/선정적 내용',
        'ILLEGAL' => '불법 콘텐츠',
        'HARASSMENT' => '괴롭힘',
        'ETC' => '기타',
        _ => reportReason,
      };
}

class ReportDetailModel extends ReportSummaryModel {
  final String targetContent;

  const ReportDetailModel({
    required super.reportId,
    required super.reporterId,
    required super.reporterNickname,
    required super.reportedUserId,
    required super.reportedUserNickname,
    required super.targetType,
    required super.targetId,
    required this.targetContent,
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
      targetContent: json['targetContent'] as String? ?? '',
      reportReason: json['reportReason'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }
}
