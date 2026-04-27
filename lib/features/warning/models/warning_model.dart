class UnreadWarningModel {
  final int warningId;
  final String adminComment;
  final DateTime issuedAt;

  const UnreadWarningModel({
    required this.warningId,
    required this.adminComment,
    required this.issuedAt,
  });

  factory UnreadWarningModel.fromJson(Map<String, dynamic> json) {
    return UnreadWarningModel(
      warningId: (json['warningId'] as num).toInt(),
      adminComment: json['adminComment'] as String? ?? '',
      issuedAt: DateTime.parse(json['issuedAt'] as String),
    );
  }
}
