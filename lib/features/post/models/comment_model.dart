class CommentModel {
  final int commentId;
  final bool isMine;
  final int? authorUserId;  // 작성자 userId (채팅 유입용, 삭제 시 null)
  final String commentStatus;
  final String content;
  final String author;
  final int likeCount;
  final int dislikeCount;
  final bool anonymous;
  final int depth;
  final int? parentId;
  final String? createdAt;

  const CommentModel({
    required this.commentId,
    required this.isMine,
    this.authorUserId,
    required this.commentStatus,
    required this.content,
    required this.author,
    required this.likeCount,
    required this.dislikeCount,
    required this.anonymous,
    required this.depth,
    required this.parentId,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: (json['commentId'] as num).toInt(),
      isMine: json['isMine'] as bool? ?? false,
      authorUserId: json['authorUserId'] != null
          ? (json['authorUserId'] as num).toInt()
          : null,
      commentStatus: json['commentStatus'] as String? ?? 'ACTIVE',
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? '',
      likeCount: json['likeCount'] != null ? (json['likeCount'] as num).toInt() : 0,
      dislikeCount: json['dislikeCount'] != null ? (json['dislikeCount'] as num).toInt() : 0,
      anonymous: json['anonymous'] as bool? ?? false,
      depth: json['depth'] != null ? (json['depth'] as num).toInt() : 0,
      parentId: json['parentId'] != null ? (json['parentId'] as num).toInt() : null,
      createdAt: json['createdAt'] as String?,
    );
  }

  bool get isReply => parentId != null;
  bool get isDeleted => commentStatus == 'DELETED';

  String get displayAuthorName => anonymous ? '익명' : author;
}