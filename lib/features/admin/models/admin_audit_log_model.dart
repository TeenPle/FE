class AdminAuditLogModel {
  final int id;
  final int adminId;
  final String adminNickname;
  final String action;
  final String targetType;
  final int targetId;
  final String? reason;
  final String? metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  const AdminAuditLogModel({
    required this.id,
    required this.adminId,
    required this.adminNickname,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.metadata,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
  });

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    return AdminAuditLogModel(
      id: (json['id'] as num).toInt(),
      adminId: (json['adminId'] as num).toInt(),
      adminNickname: json['adminNickname'] as String? ?? '관리자',
      action: json['action'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetId: (json['targetId'] as num).toInt(),
      reason: json['reason'] as String?,
      metadata: json['metadata'] as String?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
