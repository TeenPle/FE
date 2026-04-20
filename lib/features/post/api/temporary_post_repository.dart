import '../models/comment_model.dart';
import '../models/create_comment_request.dart';
import '../models/create_post_request.dart';
import '../models/post_detail.dart';
import '../models/reaction_response.dart';
import '../models/update_comment_request.dart';
import '../models/update_post_request.dart';
import 'post_repository.dart';

/// 목업 데이터로 동작하는 임시 Repository 구현체
class TemporaryPostRepository implements PostRepository {
  const TemporaryPostRepository();

  /// 임시 게시글 상세 데이터를 반환
  @override
  Future<PostDetail> getPostDetail(int postId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final comments = <CommentModel>[
      CommentModel(
        commentId: 1,
        isMine: true,
        commentStatus: 'ACTIVE',
        content: '이 글 진짜 공감돼요.',
        author: '익명',
        likeCount: 3,
        dislikeCount: 0,
        anonymous: true,
        depth: 0,
        parentId: null,
        createdAt: '방금 전',
      ),
      CommentModel(
        commentId: 2,
        isMine: false,
        commentStatus: 'ACTIVE',
        content: '저도 비슷한 경험 있었어요.',
        author: '익명',
        likeCount: 1,
        dislikeCount: 0,
        anonymous: true,
        depth: 1,
        parentId: 1,
        createdAt: '방금 전',
      ),
    ];

    return PostDetail(
      postId: postId,
      isMine: true,
      title: '샘플 게시글 제목입니다',
      content: '이곳은 게시글 본문 영역입니다. 실제 서버 연동 전까지는 임시 데이터로 화면을 확인할 수 있도록 구성했습니다.',
      viewCount: 128,
      anonymous: true,
      likeCount: 12,
      dislikeCount: 0,
      postStatus: 'NORMAL',
      username: '익명',
      createdAt: '방금 전',
      comments: comments,
    );
  }

  /// 임시 댓글 작성 처리
  @override
  Future<void> createComment({
    required int postId,
    required CreateCommentRequest request,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  /// 임시 게시글 공감 응답 반환
  @override
  Future<ReactionResponse> applyPostLike(int postId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    return ReactionResponse(
      targetId: postId,
      targetType: 'POST',
      liked: true,
      disliked: false,
      applied: true,
      likeCount: 13,
      dislikeCount: 0,
    );
  }

  /// 임시 댓글 공감 응답 반환
  @override
  Future<ReactionResponse> applyCommentLike(int commentId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    return ReactionResponse(
      targetId: commentId,
      targetType: 'COMMENT',
      liked: true,
      disliked: false,
      applied: true,
      likeCount: 1,
      dislikeCount: 0,
    );
  }

  /// 임시 게시글 신고 처리
  @override
  Future<void> reportPost(int postId, String reportReason) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// 임시 댓글 신고 처리
  @override
  Future<void> reportComment(int commentId, String reportReason) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// 임시 게시글 작성 처리 후 가짜 postId 반환
  @override
  Future<int> createPost({
    required int boardId,
    required CreatePostRequest request,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return 999;
  }

  /// 임시 게시글 수정 처리
  @override
  Future<void> updatePost({
    required int postId,
    required UpdatePostRequest request,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// 임시 게시글 삭제 처리
  @override
  Future<void> deletePost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// 임시 댓글 수정 처리
  @override
  Future<void> updateComment({
    required int commentId,
    required UpdateCommentRequest request,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// 임시 댓글 삭제 처리
  @override
  Future<void> deleteComment(int commentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}