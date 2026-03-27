class PostSummary {
  final int id;
  final String authorName;
  final bool isAnonymous;
  final String boardName;
  final String title;
  final String contentPreview;
  final String createdAt;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final int viewCount;

  const PostSummary({
    required this.id,
    required this.authorName,
    required this.isAnonymous,
    required this.boardName,
    required this.title,
    required this.contentPreview,
    required this.createdAt,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.viewCount,
  });
}