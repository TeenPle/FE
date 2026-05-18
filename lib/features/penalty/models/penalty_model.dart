class ActivePenaltyModel {
  final bool penalized;
  final DateTime? expiresAt;
  final String? reason;
  final int? reportId;

  const ActivePenaltyModel({
    required this.penalized,
    this.expiresAt,
    this.reason,
    this.reportId,
  });

  factory ActivePenaltyModel.notPenalized() =>
      const ActivePenaltyModel(penalized: false);

  factory ActivePenaltyModel.fromJson(Map<String, dynamic> json) {
    return ActivePenaltyModel(
      penalized: json['penalized'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      reason: json['reason'] as String?,
      reportId: (json['reportId'] as num?)?.toInt(),
    );
  }

  String get reasonLabel => switch (reason) {
    'SPAM' => '스팸',
    'ABUSE' => '욕설/모욕',
    'OBSCENE' => '음란물/선정적 내용',
    'ILLEGAL' => '불법 콘텐츠',
    'HARASSMENT' => '괴롭힘',
    'ETC' => '기타',
    _ => reason ?? '',
  };
}

class PenaltyHistoryModel {
  final int id;
  final String reason;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  const PenaltyHistoryModel({
    required this.id,
    required this.reason,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory PenaltyHistoryModel.fromJson(Map<String, dynamic> json) {
    return PenaltyHistoryModel(
      id: (json['penaltyId'] as num).toInt(),
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

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
