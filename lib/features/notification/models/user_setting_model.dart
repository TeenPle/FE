class UserSettingModel {
  final bool allowPush;
  final bool allowCommentNotification;
  final bool allowReplyNotification;
  final bool allowLikeNotification;
  final bool allowChatNotification;

  const UserSettingModel({
    required this.allowPush,
    required this.allowCommentNotification,
    required this.allowReplyNotification,
    required this.allowLikeNotification,
    required this.allowChatNotification,
  });

  factory UserSettingModel.fromJson(Map<String, dynamic> json) {
    return UserSettingModel(
      allowPush: json['allowPush'] as bool,
      allowCommentNotification: json['allowCommentNotification'] as bool,
      allowReplyNotification: json['allowReplyNotification'] as bool,
      allowLikeNotification: json['allowLikeNotification'] as bool,
      allowChatNotification: json['allowChatNotification'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'allowPush': allowPush,
    'allowCommentNotification': allowCommentNotification,
    'allowReplyNotification': allowReplyNotification,
    'allowLikeNotification': allowLikeNotification,
    'allowChatNotification': allowChatNotification,
  };

  UserSettingModel copyWith({
    bool? allowPush,
    bool? allowCommentNotification,
    bool? allowReplyNotification,
    bool? allowLikeNotification,
    bool? allowChatNotification,
  }) {
    return UserSettingModel(
      allowPush: allowPush ?? this.allowPush,
      allowCommentNotification:
          allowCommentNotification ?? this.allowCommentNotification,
      allowReplyNotification:
          allowReplyNotification ?? this.allowReplyNotification,
      allowLikeNotification:
          allowLikeNotification ?? this.allowLikeNotification,
      allowChatNotification:
          allowChatNotification ?? this.allowChatNotification,
    );
  }
}
