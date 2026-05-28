import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../api/post_repository.dart';
import '../models/comment_model.dart';
import '../models/create_comment_request.dart';
import '../models/update_comment_request.dart';
import '../models/update_post_request.dart';
import 'post_detail_state.dart';

/// 게시글 상세 화면 상태 관리 Notifier
class PostDetailNotifier extends StateNotifier<PostDetailState> {
  final PostRepository repository;

  PostDetailNotifier({required int postId, required this.repository})
    : super(PostDetailState.initial(postId));

  /// 게시글 상세 데이터를 조회
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

  /// 당겨서 새로고침 시 상세 데이터를 다시 조회
  Future<void> refresh() {
    return loadPostDetail(isRefresh: true);
  }

  /// 게시글 공감 처리
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

  /// 댓글 공감 처리
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

      final currentPost = state.post;

      state = state.copyWith(
        comments: updatedComments,
        likedCommentIds: updatedLikedCommentIds,
        post: currentPost?.copyWith(comments: updatedComments),
        isSubmittingReaction: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSubmittingReaction: false,
        errorMessage: '댓글 공감 처리에 실패했어요.',
      );
    }
  }

  /// 댓글 익명 여부 토글
  void toggleCommentAnonymous(bool value) {
    state = state.copyWith(commentAnonymous: value);
  }

  /// 답글 작성 대상을 설정 (같은 댓글 재탭 시 취소)
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

  /// 답글 작성 상태를 해제
  void cancelReply() {
    state = state.copyWith(clearReplying: true);
  }

  /// 댓글 작성 요청 후 상세 재조회
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
        anonymous: state.commentAnonymous,
        parentId: state.replyingToCommentId,
      );

      await repository.createComment(postId: state.postId, request: request);

      await loadPostDetail();

      state = state.copyWith(
        isSubmittingComment: false,
        clearReplying: true,
        successMessage: '댓글을 등록했어요.',
      );
    } catch (_) {
      state = state.copyWith(
        isSubmittingComment: false,
        errorMessage: '댓글 작성에 실패했어요.',
      );
    }
  }

  /// 게시글 신고 요청
  Future<void> reportPost(String reportReason) async {
    if (state.post == null || state.isReporting) return;

    state = state.copyWith(
      isReporting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.reportPost(state.postId, reportReason);

      state = state.copyWith(isReporting: false, successMessage: '게시글을 신고했어요.');
    } catch (e, st) {
      if (kDebugMode) debugPrint('reportPost error: $e\n$st');
      final message = e is ApiException ? e.message : '게시글 신고에 실패했어요.';
      state = state.copyWith(isReporting: false, errorMessage: message);
    }
  }

  /// 댓글 신고 요청
  Future<void> reportComment(int commentId, String reportReason) async {
    if (state.isReporting) return;

    state = state.copyWith(
      isReporting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.reportComment(commentId, reportReason);

      state = state.copyWith(isReporting: false, successMessage: '댓글을 신고했어요.');
    } catch (e, st) {
      if (kDebugMode) debugPrint('reportComment error: $e\n$st');
      final message = e is ApiException ? e.message : '댓글 신고에 실패했어요.';
      state = state.copyWith(isReporting: false, errorMessage: message);
    }
  }

  /// 게시글 수정 요청 후 상세 재조회
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
          anonymous: anonymous,
        ),
      );

      await loadPostDetail();

      state = state.copyWith(isUpdating: false, successMessage: '게시글을 수정했어요.');
    } catch (_) {
      state = state.copyWith(isUpdating: false, errorMessage: '게시글 수정에 실패했어요.');
    }
  }

  /// 게시글 삭제 요청 후 화면 종료 플래그를 올림
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
        successMessage: '게시글을 삭제했어요.',
        shouldClosePage: true,
      );
    } catch (_) {
      state = state.copyWith(isDeleting: false, errorMessage: '게시글 삭제에 실패했어요.');
    }
  }

  /// 댓글 수정 요청 후 상세 재조회
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
        request: UpdateCommentRequest(content: content, anonymous: anonymous),
      );

      await loadPostDetail();

      state = state.copyWith(isUpdating: false, successMessage: '댓글을 수정했어요.');
    } catch (_) {
      state = state.copyWith(isUpdating: false, errorMessage: '댓글 수정에 실패했어요.');
    }
  }

  /// 댓글 삭제 요청 후 상세 재조회
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

      state = state.copyWith(isDeleting: false, successMessage: '댓글을 삭제했어요.');
    } catch (_) {
      state = state.copyWith(isDeleting: false, errorMessage: '댓글 삭제에 실패했어요.');
    }
  }

  /// 에러/성공 메시지를 초기화
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// 페이지 종료 플래그를 해제
  void clearClosePageFlag() {
    state = state.copyWith(shouldClosePage: false);
  }

  /// 북마크 토글
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
