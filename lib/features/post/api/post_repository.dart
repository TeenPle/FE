import '../models/create_comment_request.dart';
import '../models/post_detail.dart';
import '../models/reaction_response.dart';

abstract class PostRepository {
  Future<PostDetail> getPostDetail(int postId);

  Future<void> createComment({
    required int postId,
    required CreateCommentRequest request,
  });

  Future<ReactionResponse> applyPostLike(int postId);
}