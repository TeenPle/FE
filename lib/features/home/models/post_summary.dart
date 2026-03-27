class PostSummary {
  final int id;
  final String title;
  final String content;
  final String username;
  final bool anonymous;
  final String boardName;
  final String createdAt;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final int viewCount;

  const PostSummary({
    required this.id,
    required this.title,
    required this.content,
    required this.username,
    required this.anonymous,
    required this.boardName,
    required this.createdAt,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.viewCount,
  });

  String get displayAuthorName => anonymous ? '익명' : username;
}