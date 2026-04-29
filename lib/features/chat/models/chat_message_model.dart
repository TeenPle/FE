class ChatMessageModel {
  final int messageId;
  final int roomId;
  final int senderId;
  final String type; // TEXT or IMAGE
  final String? content;
  final String? imageUrl;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.type,
    this.content,
    this.imageUrl,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final medias = json['medias'] as List<dynamic>? ?? [];
    String? imageUrl;
    if (medias.isNotEmpty) {
      imageUrl = (medias.first as Map<String, dynamic>)['url'] as String?;
    }

    return ChatMessageModel(
      messageId: (json['messageId'] as num).toInt(),
      roomId: (json['roomId'] as num).toInt(),
      senderId: (json['senderId'] as num).toInt(),
      type: json['type'] as String? ?? 'TEXT',
      content: json['content'] as String?,
      imageUrl: imageUrl,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  bool get isImage => type == 'IMAGE';
}
