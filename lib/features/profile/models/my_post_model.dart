class MyPostModel {
  final int postId;
  final String title;
  final String content;
  final String postStatus;
  final int likeCount;
  final int commentCount;
  final String? createdAt;
  final String? boardTitle;

  const MyPostModel({
    required this.postId,
    required this.title,
    required this.content,
    required this.postStatus,
    required this.likeCount,
    required this.commentCount,
    this.createdAt,
    this.boardTitle,
  });

  factory MyPostModel.fromJson(Map<String, dynamic> json) {
    return MyPostModel(
      postId: (json['postId'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      postStatus: json['postStatus'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String?,
      boardTitle: json['boardTitle'] as String?,
    );
  }

  String get preview {
    if (content.length <= 80) return content;
    return '${content.substring(0, 80)}...';
  }
}
