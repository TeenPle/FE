import 'package:dio/dio.dart';

import '../models/create_comment_request.dart';
import '../models/create_post_request.dart';
import '../models/post_detail.dart';
import '../models/reaction_response.dart';
import '../models/update_comment_request.dart';
import '../models/update_post_request.dart';

/// 게시글 관련 기능에 대한 추상 Repository
abstract class PostRepository {
  /// 게시글 상세 조회
  Future<PostDetail> getPostDetail(int postId);

  /// 댓글 작성
  Future<void> createComment({
    required int postId,
    required CreateCommentRequest request,
  });

  /// 게시글 공감 처리
  Future<ReactionResponse> applyPostLike(int postId);

  /// 댓글 공감 처리
  Future<ReactionResponse> applyCommentLike(int commentId);

  /// 게시글 신고
  Future<void> reportPost(int postId, String reportReason);

  /// 댓글 신고
  Future<void> reportComment(int commentId, String reportReason);

  /// 게시글 작성 (files: 첨부파일 목록, 없으면 빈 리스트)
  Future<int> createPost({
    required int boardId,
    required CreatePostRequest request,
    List<MultipartFile> files,
  });

  /// 게시글 수정 (files: 새로 추가할 첨부파일 목록, 없으면 빈 리스트)
  Future<void> updatePost({
    required int postId,
    required UpdatePostRequest request,
    List<MultipartFile> files,
  });

  /// 게시글 삭제
  Future<void> deletePost(int postId);

  /// 댓글 수정
  Future<void> updateComment({
    required int commentId,
    required UpdateCommentRequest request,
  });

  /// 댓글 삭제
  Future<void> deleteComment(int commentId);

  /// 북마크 토글 — true: 추가됨, false: 해제됨
  Future<bool> toggleBookmark(int postId);
}