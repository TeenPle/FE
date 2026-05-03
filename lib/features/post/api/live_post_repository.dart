import 'package:dio/dio.dart';

import '../models/create_comment_request.dart';
import '../models/create_post_request.dart';
import '../models/post_detail.dart';
import '../models/reaction_request.dart';
import '../models/reaction_response.dart';
import '../models/report_request.dart';
import '../models/update_comment_request.dart';
import '../models/update_post_request.dart';
import 'post_api.dart';
import 'post_repository.dart';

/// 실제 서버와 연결되는 게시글 Repository 구현체
class LivePostRepository implements PostRepository {
  final PostApi api;

  const LivePostRepository({
    required this.api,
  });

  /// 게시글 상세 조회를 서버에 요청
  @override
  Future<PostDetail> getPostDetail(int postId) {
    return api.getPostDetail(postId);
  }

  /// 댓글 작성 요청을 서버에 전달
  @override
  Future<void> createComment({
    required int postId,
    required CreateCommentRequest request,
  }) async {
    await api.createComment(
      postId: postId,
      request: request,
    );
  }

  /// 게시글 공감 요청을 서버에 전달
  @override
  Future<ReactionResponse> applyPostLike(int postId) {
    return api.applyReaction(
      request: ReactionRequest(
        targetType: 'POST',
        targetId: postId,
        action: 'LIKE',
      ),
    );
  }

  /// 댓글 공감 요청을 서버에 전달
  @override
  Future<ReactionResponse> applyCommentLike(int commentId) {
    return api.applyReaction(
      request: ReactionRequest(
        targetType: 'COMMENT',
        targetId: commentId,
        action: 'LIKE',
      ),
    );
  }

  /// 게시글 신고 요청을 서버에 전달
  @override
  Future<void> reportPost(int postId, String reportReason) async {
    await api.report(
      request: ReportRequest(
        targetType: 'POST',
        targetId: postId,
        reportReason: reportReason,
      ),
    );
  }

  /// 댓글 신고 요청을 서버에 전달
  @override
  Future<void> reportComment(int commentId, String reportReason) async {
    await api.report(
      request: ReportRequest(
        targetType: 'COMMENT',
        targetId: commentId,
        reportReason: reportReason,
      ),
    );
  }

  /// 게시글 작성 요청을 서버에 전달
  @override
  Future<int> createPost({
    required int boardId,
    required CreatePostRequest request,
    List<MultipartFile> files = const [],
  }) {
    return api.createPost(
      boardId: boardId,
      request: request,
      files: files,
    );
  }

  /// 게시글 수정 요청을 서버에 전달
  @override
  Future<void> updatePost({
    required int postId,
    required UpdatePostRequest request,
    List<MultipartFile> files = const [],
  }) {
    return api.updatePost(
      postId: postId,
      request: request,
      files: files,
    );
  }

  /// 게시글 삭제 요청을 서버에 전달
  @override
  Future<void> deletePost(int postId) {
    return api.deletePost(postId);
  }

  /// 댓글 수정 요청을 서버에 전달
  @override
  Future<void> updateComment({
    required int commentId,
    required UpdateCommentRequest request,
  }) {
    return api.updateComment(
      commentId: commentId,
      request: request,
    );
  }

  /// 댓글 삭제 요청을 서버에 전달
  @override
  Future<void> deleteComment(int commentId) {
    return api.deleteComment(commentId);
  }

  /// 북마크 토글 요청을 서버에 전달
  @override
  Future<bool> toggleBookmark(int postId) {
    return api.toggleBookmark(postId);
  }
}