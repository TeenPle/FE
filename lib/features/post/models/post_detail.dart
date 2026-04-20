import 'comment_model.dart';

class PostDetail {
  final int postId;
  final bool isMine;
  final String title;
  final String content;
  final int viewCount;
  final bool anonymous;
  final int likeCount;
  final int dislikeCount;
  final String postStatus;
  final String username;
  final String createdAt;
  final List<CommentModel> comments;

  const PostDetail({
    required this.postId,
    required this.isMine,
    required this.title,
    required this.content,
    required this.viewCount,
    required this.anonymous,
    required this.likeCount,
    required this.dislikeCount,
    required this.postStatus,
    required this.username,
    required this.createdAt,
    required this.comments,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    return PostDetail(
      postId: json['postId'] as int,
      isMine: json['isMine'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      viewCount: json['viewCount'] as int? ?? 0,
      anonymous: json['anonymous'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      dislikeCount: json['dislikeCount'] as int? ?? 0,
      postStatus: json['postStatus'] as String? ?? '',
      username: json['username'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get displayAuthorName => anonymous ? '익명' : username;
}