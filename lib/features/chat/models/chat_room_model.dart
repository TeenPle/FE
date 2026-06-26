class ChatRoomModel {
  final int roomId;
  final int otherUserId;
  final String displayName;
  final String lastPreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool blocked;
  final bool blockedByMe;
  final bool blockedByOther;
  final bool otherUserDeleted;
  final bool canSendMessage;
  final bool canReport;
  final bool canBlock;

  const ChatRoomModel({
    required this.roomId,
    required this.otherUserId,
    required this.displayName,
    required this.lastPreview,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.blocked,
    required this.blockedByMe,
    required this.blockedByOther,
    this.otherUserDeleted = false,
    this.canSendMessage = true,
    this.canReport = true,
    this.canBlock = true,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      roomId: (json['roomId'] as num).toInt(),
      otherUserId: (json['otherUserId'] as num).toInt(),
      displayName: json['displayName'] as String? ?? '채팅방',
      lastPreview: json['lastPreview'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] != null
          ? (json['unreadCount'] as num).toInt()
          : 0,
      blocked: json['blocked'] as bool? ?? false,
      blockedByMe: json['blockedByMe'] as bool? ?? false,
      blockedByOther: json['blockedByOther'] as bool? ?? false,
      otherUserDeleted: json['otherUserDeleted'] as bool? ?? false,
      canSendMessage: json['canSendMessage'] as bool? ?? true,
      canReport: json['canReport'] as bool? ?? true,
      canBlock: json['canBlock'] as bool? ?? true,
    );
  }
}
