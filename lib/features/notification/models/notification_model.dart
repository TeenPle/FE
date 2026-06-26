class NotificationModel {
  final int id;
  final String type;
  final String targetType;
  final int targetId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? boardName;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.targetType,
    required this.targetId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.boardName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw as String) ?? DateTime.now()
        : DateTime.now();

    return NotificationModel(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      targetType: json['targetType'] as String,
      targetId: (json['targetId'] as num).toInt(),
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: createdAt,
      boardName: json['boardName'] as String?,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      targetType: targetType,
      targetId: targetId,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      boardName: boardName,
    );
  }
}
