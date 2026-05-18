class PenaltySummaryModel {
  final int penaltyId;
  final int userId;
  final String userNickname;
  final int reportId;
  final String reason;
  final String status; // ACTIVE | CANCELLED | EXPIRED
  final DateTime expiresAt;
  final DateTime createdAt;

  const PenaltySummaryModel({
    required this.penaltyId,
    required this.userId,
    required this.userNickname,
    required this.reportId,
    required this.reason,
    this.status = 'ACTIVE',
    required this.expiresAt,
    required this.createdAt,
  });

  factory PenaltySummaryModel.fromJson(Map<String, dynamic> json) {
    return PenaltySummaryModel(
      penaltyId: (json['penaltyId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userNickname: json['userNickname'] as String? ?? '',
      reportId: (json['reportId'] as num).toInt(),
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isActive => status == 'ACTIVE' && !isExpired;

  String get reasonLabel => switch (reason) {
    'SPAM' => '스팸',
    'ABUSE' => '욕설/모욕',
    'OBSCENE' => '음란물/선정적 내용',
    'ILLEGAL' => '불법 콘텐츠',
    'HARASSMENT' => '괴롭힘',
    'ETC' => '기타',
    _ => reason,
  };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
