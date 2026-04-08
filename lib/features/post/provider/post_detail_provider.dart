import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/post_repository.dart';
import '../models/comment_model.dart';
import '../models/create_comment_request.dart';
import 'post_detail_state.dart';
import '../models/post_detail.dart';

class PostDetailNotifier extends StateNotifier<PostDetailState> {
  final PostRepository repository;

  PostDetailNotifier({
    required int postId,
    required this.repository,
  }) : super(PostDetailState.initial(postId));

  Future<void> loadPostDetail() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final post = await repository.getPostDetail(state.postId);

      state = state.copyWith(
        post: post,
        comments: post.comments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '게시글을 불러오지 못했습니다.',
      );
    }
  }

  Future<void> toggleLike() async {
    if (state.post == null) return;

    try {
      final result = await repository.applyPostLike(state.postId);

      final currentPost = state.post!;
      final updatedPost = PostDetail(
        postId: currentPost.postId,
        title: currentPost.title,
        content: currentPost.content,
        viewCount: currentPost.viewCount,
        anonymous: currentPost.anonymous,
        likeCount: result.likeCount,
        dislikeCount: result.dislikeCount,
        postStatus: currentPost.postStatus,
        username: currentPost.username,
        createdAt: currentPost.createdAt,
        comments: currentPost.comments,
      );

      state = state.copyWith(
        post: updatedPost,
        likedByMe: result.liked,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '좋아요 처리에 실패했습니다.');
    }
  }

  void toggleCommentAnonymous(bool value) {
    state = state.copyWith(commentAnonymous: value);
  }

  void startReply(int commentId, {required bool isReply}) {
    if (isReply) return; // 1depth 제한: 대댓글에는 다시 답글 달기 불가

    state = state.copyWith(replyingToCommentId: commentId);
  }

  void cancelReply() {
    state = state.copyWith(clearReplying: true);
  }

  Future<void> submitComment(String content) async {
    if (content.trim().isEmpty) return;

    state = state.copyWith(
      isSubmittingComment: true,
      clearError: true,
    );

    try {
      final request = CreateCommentRequest(
        content: content.trim(),
        anonymous: state.commentAnonymous,
        parentId: state.replyingToCommentId,
      );

      await repository.createComment(
        postId: state.postId,
        request: request,
      );

      await loadPostDetail();

      state = state.copyWith(
        isSubmittingComment: false,
        clearReplying: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmittingComment: false,
        errorMessage: '댓글 작성에 실패했습니다.',
      );
    }
  }
}