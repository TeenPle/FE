class ReportRequest {
  final String targetType;
  final int targetId;
  final String reportReason;

  const ReportRequest({
    required this.targetType,
    required this.targetId,
    required this.reportReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetType': targetType,
      'targetId': targetId,
      'reportReason': reportReason,
    };
  }
}
