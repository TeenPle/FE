import 'comment_model.dart';
import 'post_media_item.dart';
import 'poll_model.dart';

class PostDetail {
  final int postId;
  final int? authorUserId;
  final bool isMine;
  final int? authorId;  // 게시글 작성자 userId (채팅 유입용)
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
  final int? createdAtMs;
  final List<CommentModel> comments;
  final List<PostMediaItem> mediaList;
  final bool isBookmarked;
  final PollModel? poll;

  const PostDetail({
    required this.postId,
    this.authorUserId,
    required this.isMine,
    this.authorId,
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
    this.createdAtMs,
    required this.comments,
    this.mediaList = const [],
    this.isBookmarked = false,
    this.poll,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    final rawProfileUrl = json['authorProfileImageUrl'] as String?;
    return PostDetail(
      postId: (json['postId'] as num).toInt(),
      authorUserId: json['authorUserId'] != null ? (json['authorUserId'] as num).toInt() : null,
      isMine: json['isMine'] as bool? ?? false,
      authorId: json['authorId'] != null ? (json['authorId'] as num).toInt() : null,
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
      createdAtMs: json['createdAtMs'] != null ? (json['createdAtMs'] as num).toInt() : null,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaList: (json['mediaList'] as List<dynamic>? ?? [])
          .map((e) => PostMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      poll: json['poll'] != null
          ? PollModel.fromJson(json['poll'] as Map<String, dynamic>)
          : null,
    );
  }

  PostDetail copyWith({
    int? postId,
    int? authorUserId,
    bool? isMine,
    int? authorId,
    String? title,
    String? content,
    int? viewCount,
    bool? anonymous,
    int? likeCount,
    int? dislikeCount,
    String? postStatus,
    String? username,
    String? authorProfileImageUrl,
    String? createdAt,
    int? createdAtMs,
    List<CommentModel>? comments,
    List<PostMediaItem>? mediaList,
    bool? isBookmarked,
    PollModel? poll,
  }) {
    return PostDetail(
      postId: postId ?? this.postId,
      authorUserId: authorUserId ?? this.authorUserId,
      isMine: isMine ?? this.isMine,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      content: content ?? this.content,
      viewCount: viewCount ?? this.viewCount,
      anonymous: anonymous ?? this.anonymous,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      postStatus: postStatus ?? this.postStatus,
      username: username ?? this.username,
      authorProfileImageUrl: authorProfileImageUrl ?? this.authorProfileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      comments: comments ?? this.comments,
      mediaList: mediaList ?? this.mediaList,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      poll: poll ?? this.poll,
    );
  }

  List<String> get mediaUrls => mediaList.map((m) => m.url).toList();

  String get displayAuthorName => anonymous ? '익명' : username;
}
