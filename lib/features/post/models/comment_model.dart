class CommentModel {
  final int commentId;
  final int? authorUserId;
  final bool isMine;
  final bool authorDeleted;
  final bool canChatWithAuthor;
  final bool canReportAuthor;
  final bool canBlockAuthor;
  final String commentStatus;
  final String content;
  final String author;
  final int likeCount;
  final int dislikeCount;
  final bool likedByMe;
  final bool anonymous;
  final int depth;
  final int? parentId;
  final String? createdAt;
  final int? createdAtMs;

  const CommentModel({
    required this.commentId,
    this.authorUserId,
    required this.isMine,
    this.authorDeleted = false,
    this.canChatWithAuthor = true,
    this.canReportAuthor = true,
    this.canBlockAuthor = true,
    required this.commentStatus,
    required this.content,
    required this.author,
    required this.likeCount,
    required this.dislikeCount,
    required this.likedByMe,
    required this.anonymous,
    required this.depth,
    required this.parentId,
    required this.createdAt,
    this.createdAtMs,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: (json['commentId'] as num).toInt(),
      authorUserId: json['authorUserId'] != null ? (json['authorUserId'] as num).toInt() : null,
      isMine: json['isMine'] as bool? ?? false,
      authorDeleted: json['authorDeleted'] as bool? ?? false,
      canChatWithAuthor: json['canChatWithAuthor'] as bool? ?? true,
      canReportAuthor: json['canReportAuthor'] as bool? ?? true,
      canBlockAuthor: json['canBlockAuthor'] as bool? ?? true,
      commentStatus: json['commentStatus'] as String? ?? 'ACTIVE',
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? '',
      likeCount: json['likeCount'] != null ? (json['likeCount'] as num).toInt() : 0,
      dislikeCount: json['dislikeCount'] != null ? (json['dislikeCount'] as num).toInt() : 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      anonymous: json['anonymous'] as bool? ?? false,
      depth: json['depth'] != null ? (json['depth'] as num).toInt() : 0,
      parentId: json['parentId'] != null ? (json['parentId'] as num).toInt() : null,
      createdAt: json['createdAt'] as String?,
      createdAtMs: json['createdAtMs'] != null ? (json['createdAtMs'] as num).toInt() : null,
    );
  }

  bool get isReply => parentId != null;
  bool get isDeleted => commentStatus == 'DELETED';

  String get displayAuthorName => authorDeleted ? '탈퇴한 사용자' : author;
}
