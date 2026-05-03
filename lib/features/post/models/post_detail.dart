import 'comment_model.dart';
import 'post_media_item.dart';

class PostDetail {
  final int postId;
  final int? authorUserId;
  final bool isMine;
  final String title;
  final String content;
  final int viewCount;
  final bool anonymous;
  final int likeCount;
  final int dislikeCount;
  final String postStatus;
  final String username;
  final String? authorProfileImageUrl;
  final String createdAt;
  final List<CommentModel> comments;
  final List<PostMediaItem> mediaList;
  final bool isBookmarked;

  const PostDetail({
    required this.postId,
    this.authorUserId,
    required this.isMine,
    required this.title,
    required this.content,
    required this.viewCount,
    required this.anonymous,
    required this.likeCount,
    required this.dislikeCount,
    required this.postStatus,
    required this.username,
    this.authorProfileImageUrl,
    required this.createdAt,
    required this.comments,
    this.mediaList = const [],
    this.isBookmarked = false,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    final rawProfileUrl = json['authorProfileImageUrl'] as String?;
    return PostDetail(
      postId: (json['postId'] as num).toInt(),
      authorUserId: json['authorUserId'] != null ? (json['authorUserId'] as num).toInt() : null,
      isMine: json['isMine'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      viewCount: json['viewCount'] != null ? (json['viewCount'] as num).toInt() : 0,
      anonymous: json['anonymous'] as bool? ?? false,
      likeCount: json['likeCount'] != null ? (json['likeCount'] as num).toInt() : 0,
      dislikeCount: json['dislikeCount'] != null ? (json['dislikeCount'] as num).toInt() : 0,
      postStatus: json['postStatus'] as String? ?? '',
      username: json['username'] as String? ?? '',
      authorProfileImageUrl: (rawProfileUrl != null && rawProfileUrl.startsWith('http'))
          ? rawProfileUrl
          : null,
      createdAt: json['createdAt'] as String? ?? '',
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaList: (json['mediaList'] as List<dynamic>? ?? [])
          .map((e) => PostMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  List<String> get mediaUrls => mediaList.map((m) => m.url).toList();

  String get displayAuthorName => anonymous ? '익명' : username;
}