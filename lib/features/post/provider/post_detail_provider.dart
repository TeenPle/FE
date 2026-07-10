import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../profile/provider/block_provider.dart';
import '../api/post_repository.dart';
import '../models/comment_model.dart';
import '../models/create_comment_request.dart';
import '../models/update_comment_request.dart';
import '../models/update_post_request.dart';
import 'post_detail_state.dart';

class PostDetailNotifier extends StateNotifier<PostDetailState> {
  final PostRepository repository;
  final BlockAction blockAction;

  PostDetailNotifier({
    required int postId,
    required this.repository,
    required this.blockAction,
  }) : super(PostDetailState.initial(postId));

  Future<void> loadPostDetail({bool isRefresh = false}) async {
    state = state.copyWith(
      isLoading: !isRefresh && state.post == null,
      isRefreshing: isRefresh,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final post = await repository.getPostDetail(state.postId);
      state = state.copyWith(
        post: post,
        comments: post.comments,
        isLoading: false,
        isRefreshing: false,
        bookmarkedByMe: post.isBookmarked,
        likedByMe: post.likedByMe,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: '게시글을 불러오지 못했어요.',
      );
    }
  }

  Future<void> refresh() {
    return loadPostDetail(isRefresh: true);
  }

  Future<void> toggleLike() async {
    if (state.post == null || state.isSubmittingReaction) return;

    state = state.copyWith(
      isSubmittingReaction: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final result = await repository.applyPostLike(state.postId);
      final currentPost = state.post!;
      final updatedPost = currentPost.copyWith(
        likeCount: result.likeCount,
        dislikeCount: result.dislikeCount,
        likedByMe: result.liked,
        dislikedByMe: result.disliked,
        comments: state.comments,
      );

      state = state.copyWith(
        post: updatedPost,
        likedByMe: result.liked,
        isSubmittingReaction: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSubmittingReaction: false,
        errorMessage: '공감 처리에 실패했어요.',
      );
    }
  }

  Future<void> likeComment(int commentId) async {
    if (state.isSubmittingReaction) return;

    state = state.copyWith(
      isSubmittingReaction: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final result = await repository.applyCommentLike(commentId);
      final updatedComments = state.comments.map((comment) {
        if (comment.commentId != commentId) return comment;
        return CommentModel(
          commentId: comment.commentId,
          authorUserId: comment.authorUserId,
          isMine: comment.isMine,
          isPostAuthor: comment.isPostAuthor,
          authorDeleted: comment.authorDeleted,
          canChatWithAuthor: comment.canChatWithAuthor,
          canReportAuthor: comment.canReportAuthor,
          canBlockAuthor: comment.canBlockAuthor,
          commentStatus: comment.commentStatus,
          content: comment.content,
          author: comment.author,
          authorProfileImageUrl: comment.authorProfileImageUrl,
          likeCount: result.likeCount,
          dislikeCount: result.dislikeCount,
          likedByMe: result.liked,
          anonymous: comment.anonymous,
          depth: comment.depth,
          parentId: comment.parentId,
          createdAt: comment.createdAt,
          createdAtMs: comment.createdAtMs,
        );
      }).toList();

      final updatedLikedCommentIds = Set<int>.from(state.likedCommentIds);
      if (result.liked) {
        updatedLikedCommentIds.add(commentId);
      } else {
        updatedLikedCommentIds.remove(commentId);
      }

      state = state.copyWith(
        comments: updatedComments,
        likedCommentIds: updatedLikedCommentIds,
        post: state.post?.copyWith(comments: updatedComments),
        isSubmittingReaction: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSubmittingReaction: false,
        errorMessage: '댓글 공감 처리에 실패했어요.',
      );
    }
  }

  void toggleCommentAnonymous(bool value) {
    state = state.copyWith(commentAnonymous: false);
  }

  void startReply(int commentId, {required bool isReply}) {
    if (isReply) return;
    if (state.replyingToCommentId == commentId) {
      cancelReply();
      return;
    }

    state = state.copyWith(
      replyingToCommentId: commentId,
      clearError: true,
      clearSuccess: true,
    );
  }

  void cancelReply() {
    state = state.copyWith(clearReplying: true);
  }

  Future<void> submitComment(String content) async {
    if (content.trim().isEmpty || state.isSubmittingComment) return;

    state = state.copyWith(
      isSubmittingComment: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final request = CreateCommentRequest(
        content: content.trim(),
        anonymous: false,
        parentId: state.replyingToCommentId,
      );
      await repository.createComment(postId: state.postId, request: request);
      await loadPostDetail();
      state = state.copyWith(
        isSubmittingComment: false,
        clearReplying: true,
        successMessage: '댓글이 등록되었어요.',
      );
    } catch (e) {
      if (e is ApiException) {
        state = state.copyWith(
          isSubmittingComment: false,
          errorMessage: e.message,
        );
        return;
      }
      state = state.copyWith(
        isSubmittingComment: false,
        errorMessage: '댓글 작성에 실패했어요.',
      );
    }
  }

  Future<void> reportPost(String reportReason) async {
    if (state.post == null || state.isReporting) return;
    final post = state.post!;

    state = state.copyWith(
      isReporting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.reportPost(state.postId, reportReason);
      final shouldBlock = post.canBlockAuthor && post.authorUserId != null;
      if (shouldBlock) await blockAction.block(post.authorUserId!);

      state = state.copyWith(
        isReporting: false,
        successMessage: shouldBlock
            ? _reportAndBlockMessage
            : _reportOnlyMessage,
        shouldClosePage: shouldBlock,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('reportPost error: $e\n$st');
      final message = e is ApiException ? e.message : '게시글 신고 및 차단에 실패했어요.';
      state = state.copyWith(isReporting: false, errorMessage: message);
    }
  }

  Future<void> reportComment(int commentId, String reportReason) async {
    if (state.isReporting) return;
    final comment = _findComment(commentId);

    state = state.copyWith(
      isReporting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.reportComment(commentId, reportReason);
      final blockedUserId = comment?.authorUserId;
      final shouldBlock =
          comment?.canBlockAuthor == true && blockedUserId != null;
      if (shouldBlock) await blockAction.block(comment!.authorUserId!);

      state = state.copyWith(
        isReporting: false,
        comments: shouldBlock
            ? state.comments
                  .where((item) => item.authorUserId != blockedUserId)
                  .toList()
            : null,
        successMessage: shouldBlock
            ? _reportAndBlockMessage
            : _reportOnlyMessage,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('reportComment error: $e\n$st');
      final message = e is ApiException ? e.message : '댓글 신고 및 차단에 실패했어요.';
      state = state.copyWith(isReporting: false, errorMessage: message);
    }
  }

  CommentModel? _findComment(int commentId) {
    for (final comment in state.comments) {
      if (comment.commentId == commentId) return comment;
    }
    return null;
  }

  static const String _reportAndBlockMessage =
      '신고가 접수되고 해당 사용자가 차단되었어요.\n운영자가 24시간 내 검토해 콘텐츠 삭제나 작성자 제재를 처리합니다.';
  static const String _reportOnlyMessage =
      '신고가 접수되었어요.\n운영자가 24시간 내 검토해 콘텐츠 삭제나 작성자 제재를 처리합니다.';

  Future<void> updatePost({
    required String title,
    required String content,
    required bool anonymous,
  }) async {
    if (state.isUpdating) return;

    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.updatePost(
        postId: state.postId,
        request: UpdatePostRequest(
          title: title,
          content: content,
          anonymous: false,
        ),
      );
      await loadPostDetail();
      state = state.copyWith(isUpdating: false, successMessage: '게시글이 수정되었어요.');
    } catch (_) {
      state = state.copyWith(isUpdating: false, errorMessage: '게시글 수정에 실패했어요.');
    }
  }

  Future<void> deletePost() async {
    if (state.isDeleting) return;

    state = state.copyWith(
      isDeleting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.deletePost(state.postId);
      state = state.copyWith(
        isDeleting: false,
        successMessage: '게시글이 삭제되었어요.',
        shouldClosePage: true,
      );
    } catch (_) {
      state = state.copyWith(isDeleting: false, errorMessage: '게시글 삭제에 실패했어요.');
    }
  }

  Future<void> updateComment({
    required int commentId,
    required String content,
    required bool anonymous,
  }) async {
    if (state.isUpdating) return;

    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.updateComment(
        commentId: commentId,
        request: UpdateCommentRequest(content: content, anonymous: false),
      );
      await loadPostDetail();
      state = state.copyWith(isUpdating: false, successMessage: '댓글이 수정되었어요.');
    } catch (e) {
      if (e is ApiException) {
        state = state.copyWith(isUpdating: false, errorMessage: e.message);
        return;
      }
      state = state.copyWith(isUpdating: false, errorMessage: '댓글 수정에 실패했어요.');
    }
  }

  Future<void> deleteComment(int commentId) async {
    if (state.isDeleting) return;

    state = state.copyWith(
      isDeleting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.deleteComment(commentId);
      await loadPostDetail();
      state = state.copyWith(isDeleting: false, successMessage: '댓글이 삭제되었어요.');
    } catch (_) {
      state = state.copyWith(isDeleting: false, errorMessage: '댓글 삭제에 실패했어요.');
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearClosePageFlag() {
    state = state.copyWith(shouldClosePage: false);
  }

  Future<void> toggleBookmark() async {
    if (state.post == null || state.isBookmarking) return;

    state = state.copyWith(
      isBookmarking: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final bookmarked = await repository.toggleBookmark(state.postId);
      state = state.copyWith(
        bookmarkedByMe: bookmarked,
        isBookmarking: false,
        successMessage: bookmarked ? '북마크에 추가했어요.' : '북마크를 해제했어요.',
      );
    } catch (_) {
      state = state.copyWith(
        isBookmarking: false,
        errorMessage: '북마크 처리에 실패했어요.',
      );
    }
  }

  Future<void> votePoll(int optionId) async {
    if (state.post == null || state.isSubmittingReaction) return;

    state = state.copyWith(
      isSubmittingReaction: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final poll = await repository.votePoll(
        postId: state.postId,
        optionId: optionId,
      );
      state = state.copyWith(
        post: state.post!.copyWith(poll: poll),
        isSubmittingReaction: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSubmittingReaction: false,
        errorMessage: '투표 처리에 실패했어요.',
      );
    }
  }
}
