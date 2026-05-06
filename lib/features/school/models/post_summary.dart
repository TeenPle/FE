import '../../../features/post/models/post_media_item.dart';

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
  final String? authorProfileImageUrl;
  final int commentCount;
  final List<PostMediaItem> mediaList;
  final String createdAt;
  final int? createdAtMs;
  final bool hasPoll;

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
    this.authorProfileImageUrl,
    required this.commentCount,
    this.mediaList = const [],
    this.createdAt = '',
    this.createdAtMs,
    this.hasPoll = false,
  });

  factory PostSummary.fromJson(Map<String, dynamic> json) {
    final rawProfileUrl = json['authorProfileImageUrl'] as String?;
    return PostSummary(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      postStatus: json['postStatus'] as String? ?? '',
      viewCount: json['viewCount'] != null ? (json['viewCount'] as num).toInt() : 0,
      anonymous: json['anonymous'] as bool? ?? false,
      likeCount: json['likeCount'] != null ? (json['likeCount'] as num).toInt() : 0,
      dislikeCount: json['dislikeCount'] != null ? (json['dislikeCount'] as num).toInt() : 0,
      boardId: json['boardId'] != null ? (json['boardId'] as num).toInt() : 0,
      userId: json['userId'] != null ? (json['userId'] as num).toInt() : 0,
      username: json['username'] as String? ?? '',
      authorProfileImageUrl: (rawProfileUrl != null && rawProfileUrl.startsWith('http'))
          ? rawProfileUrl
          : null,
      commentCount: json['commentCount'] != null ? (json['commentCount'] as num).toInt() : 0,
      mediaList: (json['mediaList'] as List<dynamic>? ?? [])
          .map((e) => PostMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
      createdAtMs: json['createdAtMs'] != null ? (json['createdAtMs'] as num).toInt() : null,
      hasPoll: json['hasPoll'] as bool? ?? false,
    );
  }

  List<String> get mediaUrls => mediaList.map((m) => m.url).toList();

  String get displayAuthorName => anonymous ? '익명' : username;
}
