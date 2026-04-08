class CommentModel {
  final int commentId;
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
      commentId: json['commentId'] as int,
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? '',
      likeCount: json['likeCount'] as int? ?? 0,
      dislikeCount: json['dislikeCount'] as int? ?? 0,
      anonymous: json['anonymous'] as bool? ?? false,
      depth: json['depth'] as int? ?? 0,
      parentId: json['parentId'] as int?,
      createdAt: json['createdAt'] as String?,
    );
  }

  bool get isReply => parentId != null;

  String get displayAuthorName => anonymous ? '익명' : author;
}