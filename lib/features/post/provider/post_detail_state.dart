import '../models/comment_model.dart';
import '../models/post_detail.dart';

/// 게시글 상세 화면 상태
class PostDetailState {
  final int postId;
  final PostDetail? post;
  final List<CommentModel> comments;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSubmittingComment;
  final bool isSubmittingReaction;
  final bool isReporting;
  final bool isUpdating;
  final bool isDeleting;
  final bool commentAnonymous;
  final int? replyingToCommentId;
  final bool likedByMe;
  final String? errorMessage;
  final String? successMessage;
  final bool shouldClosePage;

  const PostDetailState({
    required this.postId,
    required this.post,
    required this.comments,
    required this.isLoading,
    required this.isRefreshing,
    required this.isSubmittingComment,
    required this.isSubmittingReaction,
    required this.isReporting,
    required this.isUpdating,
    required this.isDeleting,
    required this.commentAnonymous,
    required this.replyingToCommentId,
    required this.likedByMe,
    required this.errorMessage,
    required this.successMessage,
    required this.shouldClosePage,
  });

  /// 초기 상태 생성
  factory PostDetailState.initial(int postId) {
    return PostDetailState(
      postId: postId,
      post: null,
      comments: const [],
      isLoading: false,
      isRefreshing: false,
      isSubmittingComment: false,
      isSubmittingReaction: false,
      isReporting: false,
      isUpdating: false,
      isDeleting: false,
      commentAnonymous: true,
      replyingToCommentId: null,
      likedByMe: false,
      errorMessage: null,
      successMessage: null,
      shouldClosePage: false,
    );
  }

  /// 상태 일부를 복사해서 새 상태 생성
  PostDetailState copyWith({
    PostDetail? post,
    List<CommentModel>? comments,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSubmittingComment,
    bool? isSubmittingReaction,
    bool? isReporting,
    bool? isUpdating,
    bool? isDeleting,
    bool? commentAnonymous,
    int? replyingToCommentId,
    bool clearReplying = false,
    bool? likedByMe,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    bool? shouldClosePage,
  }) {
    return PostDetailState(
      postId: postId,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      isSubmittingReaction: isSubmittingReaction ?? this.isSubmittingReaction,
      isReporting: isReporting ?? this.isReporting,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      commentAnonymous: commentAnonymous ?? this.commentAnonymous,
      replyingToCommentId: clearReplying
          ? null
          : (replyingToCommentId ?? this.replyingToCommentId),
      likedByMe: likedByMe ?? this.likedByMe,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
      clearSuccess ? null : (successMessage ?? this.successMessage),
      shouldClosePage: shouldClosePage ?? this.shouldClosePage,
    );
  }
}