class MyCommentModel {
  final int commentId;
  final String content;
  final int postId;
  final String postTitle;
  final int likeCount;
  final String? createdAt;

  const MyCommentModel({
    required this.commentId,
    required this.content,
    required this.postId,
    required this.postTitle,
    required this.likeCount,
    this.createdAt,
  });

  factory MyCommentModel.fromJson(Map<String, dynamic> json) {
    return MyCommentModel(
      commentId: (json['commentId'] as num).toInt(),
      content: json['content'] as String,
      postId: (json['postId'] as num).toInt(),
      postTitle: json['postTitle'] as String,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String?,
    );
  }
}
