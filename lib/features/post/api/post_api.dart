import 'package:flutter/cupertino.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';
import '../models/create_comment_request.dart';
import '../models/create_post_request.dart';
import '../models/post_detail.dart';
import '../models/reaction_request.dart';
import '../models/reaction_response.dart';
import '../models/report_request.dart';
import '../models/update_comment_request.dart';
import '../models/update_post_request.dart';

/// 게시글 관련 실제 HTTP API 호출 담당 클래스
class PostApi {
  final AppApiClient client;

  const PostApi({
    required this.client,
  });

  /// 게시글 상세 조회 API 호출
  Future<PostDetail> getPostDetail(int postId) async {
    final json = await client.get('/api/posts/$postId');

    final response = ApiResponse.fromJson(
      json,
          (data) => PostDetail.fromJson(data as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  /// 댓글 작성 API 호출
  Future<int> createComment({
    required int postId,
    required CreateCommentRequest request,
  }) async {
    final json = await client.post(
      '/api/posts/$postId/comments',
      body: request.toJson(),
    );

    final response = ApiResponse.fromJson(
      json,
          (data) => (data as num).toInt(),
    );

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    debugPrint('댓글 작성 요청 URL = /api/posts/$postId/comments');
    debugPrint('댓글 작성 body = ${request.toJson()}');

    return response.result!;
  }

  /// 공감/비공감 반응 API 호출
  Future<ReactionResponse> applyReaction({
    required ReactionRequest request,
  }) async {
    final json = await client.post(
      '/api/reactions/apply',
      body: request.toJson(),
    );

    final response = ApiResponse.fromJson(
      json,
          (data) => ReactionResponse.fromJson(data as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  /// 신고 API 호출
  Future<int> report({
    required ReportRequest request,
  }) async {
    final json = await client.post(
      '/api/reports',
      body: request.toJson(),
    );

    final response = ApiResponse.fromJson(
      json,
          (data) {
        final map = data as Map<String, dynamic>;
        return (map['reportId'] as num).toInt();
      },
    );

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  /// 게시글 작성 API 호출 (multipart/form-data)
  Future<int> createPost({
    required int boardId,
    required CreatePostRequest request,
  }) async {
    final json = await client.postMultipart(
      '/api/boards/$boardId/posts',
      jsonBody: request.toJson(),
    );

    final response = ApiResponse.fromJson(
      json,
          (data) => (data as num).toInt(),
    );

    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }

    return response.result!;
  }

  /// 게시글 수정 API 호출 (multipart/form-data)
  Future<void> updatePost({
    required int postId,
    required UpdatePostRequest request,
  }) async {
    final json = await client.patchMultipart(
      '/api/posts/$postId',
      jsonBody: request.toJson(),
    );

    final response = ApiResponse.fromJson(
      json,
          (data) => data,
    );

    if (!response.isSuccess) {
      throw Exception(response.message);
    }
  }

  /// 게시글 삭제 API 호출
  Future<void> deletePost(int postId) async {
    final json = await client.delete('/api/posts/$postId');

    final response = ApiResponse.fromJson(
      json,
          (data) => data,
    );

    if (!response.isSuccess) {
      throw Exception(response.message);
    }
  }

  /// 댓글 수정 API 호출
  Future<void> updateComment({
    required int commentId,
    required UpdateCommentRequest request,
  }) async {
    final json = await client.patch(
      '/api/comments/$commentId',
      body: request.toJson(),
    );

    final response = ApiResponse.fromJson(
      json,
          (data) => data,
    );

    if (!response.isSuccess) {
      throw Exception(response.message);
    }
  }

  /// 댓글 삭제 API 호출
  Future<void> deleteComment(int commentId) async {
    final json = await client.delete('/api/comments/$commentId');

    final response = ApiResponse.fromJson(
      json,
          (data) => data,
    );

    if (!response.isSuccess) {
      throw Exception(response.message);
    }
  }
}