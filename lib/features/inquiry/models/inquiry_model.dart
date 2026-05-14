class InquirySummaryModel {
  final int inquiryId;
  final String title;
  final String status;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final int? userId;
  final String? userName;
  final String? userNickname;
  final String? schoolName;

  const InquirySummaryModel({
    required this.inquiryId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.answeredAt,
    this.userId,
    this.userName,
    this.userNickname,
    this.schoolName,
  });

  factory InquirySummaryModel.fromJson(Map<String, dynamic> json) {
    return InquirySummaryModel(
      inquiryId: (json['inquiryId'] as num).toInt(),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['createdAt'] as String),
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
      userId: (json['userId'] as num?)?.toInt(),
      userName: json['userName'] as String?,
      userNickname: json['userNickname'] as String?,
      schoolName: json['schoolName'] as String?,
    );
  }

  String get statusLabel => status == 'ANSWERED' ? '답변 완료' : '답변 대기';
  bool get isAnswered => status == 'ANSWERED';
}

class InquiryDetailModel extends InquirySummaryModel {
  final String content;
  final String? adminAnswer;

  const InquiryDetailModel({
    required super.inquiryId,
    required super.title,
    required super.status,
    required super.createdAt,
    super.answeredAt,
    super.userId,
    super.userName,
    super.userNickname,
    super.schoolName,
    required this.content,
    this.adminAnswer,
  });

  factory InquiryDetailModel.fromJson(Map<String, dynamic> json) {
    return InquiryDetailModel(
      inquiryId: (json['inquiryId'] as num).toInt(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      adminAnswer: json['adminAnswer'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
      userId: (json['userId'] as num?)?.toInt(),
      userName: json['userName'] as String?,
      userNickname: json['userNickname'] as String?,
      schoolName: json['schoolName'] as String?,
    );
  }
}
