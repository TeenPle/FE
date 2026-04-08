class PostSummary {
  final int id;
  final String title;
  final String content;
  final String postStatus;
  final int viewCount;
  final bool anonymous;
  final int likeCount;
  final int dislikeCount;
  final int boardId;
  final int userId;
  final String username;
  final int commentCount;

  const PostSummary({
    required this.id,
    required this.title,
    required this.content,
    required this.postStatus,
    required this.viewCount,
    required this.anonymous,
    required this.likeCount,
    required this.dislikeCount,
    required this.boardId,
    required this.userId,
    required this.username,
    required this.commentCount,
  });

  factory PostSummary.fromJson(Map<String, dynamic> json) {
    return PostSummary(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      postStatus: json['postStatus'] as String? ?? '',
      viewCount: json['viewCount'] as int? ?? 0,
      anonymous: json['anonymous'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      dislikeCount: json['dislikeCount'] as int? ?? 0,
      boardId: json['boardId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }

  String get displayAuthorName => anonymous ? '익명' : username;
}