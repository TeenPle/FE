import '../models/comment_model.dart';
import '../models/post_detail.dart';

class PostDetailState {
  final int postId;
  final PostDetail? post;
  final List<CommentModel> comments;
  final bool isLoading;
  final bool isSubmittingComment;
  final bool commentAnonymous;
  final int? replyingToCommentId;
  final bool likedByMe;
  final String? errorMessage;

  const PostDetailState({
    required this.postId,
    required this.post,
    required this.comments,
    required this.isLoading,
    required this.isSubmittingComment,
    required this.commentAnonymous,
    required this.replyingToCommentId,
    required this.likedByMe,
    required this.errorMessage,
  });

  factory PostDetailState.initial(int postId) {
    return PostDetailState(
      postId: postId,
      post: null,
      comments: const [],
      isLoading: false,
      isSubmittingComment: false,
      commentAnonymous: true,
      replyingToCommentId: null,
      likedByMe: false,
      errorMessage: null,
    );
  }

  PostDetailState copyWith({
    PostDetail? post,
    List<CommentModel>? comments,
    bool? isLoading,
    bool? isSubmittingComment,
    bool? commentAnonymous,
    int? replyingToCommentId,
    bool clearReplying = false,
    bool? likedByMe,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PostDetailState(
      postId: postId,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      commentAnonymous: commentAnonymous ?? this.commentAnonymous,
      replyingToCommentId:
      clearReplying ? null : (replyingToCommentId ?? this.replyingToCommentId),
      likedByMe: likedByMe ?? this.likedByMe,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}