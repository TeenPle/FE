import '../models/comment_model.dart';
import '../models/create_comment_request.dart';
import '../models/post_detail.dart';
import '../models/reaction_response.dart';
import 'post_repository.dart';

class TemporaryPostRepository implements PostRepository {
  const TemporaryPostRepository();

  @override
  Future<PostDetail> getPostDetail(int postId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final comments = _commentsByPostId[postId] ?? const [];

    return PostDetail(
      postId: postId,
      title: '근데 여자들은 춤추는게 즐거움?',
      content:
      '인스타보면 물론 남자애들도 끼순이 같은 애들이 춤추는거 올리긴 하는데\n'
          '남녀 비율로 봤을때 거의 9대1 정도로 여자들이 챌린지 춤 같은거 많이 올리는듯',
      viewCount: 120,
      anonymous: true,
      likeCount: 0,
      dislikeCount: 0,
      postStatus: 'NORMAL',
      username: '익명',
      createdAt: '04/07 15:16',
      comments: comments,
    );
  }

  @override
  Future<void> createComment({
    required int postId,
    required CreateCommentRequest request,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<ReactionResponse> applyPostLike(int postId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    return const ReactionResponse(
      targetId: 1,
      targetType: 'POST',
      liked: true,
      disliked: false,
      applied: true,
      likeCount: 1,
      dislikeCount: 0,
    );
  }

  static final Map<int, List<CommentModel>> _commentsByPostId = {
    1: const [
      CommentModel(
        commentId: 1,
        content: '삭제된 댓글입니다.',
        author: '(삭제)',
        likeCount: 0,
        dislikeCount: 0,
        anonymous: false,
        depth: 0,
        parentId: null,
        createdAt: '',
      ),
      CommentModel(
        commentId: 2,
        content: '머라카는교',
        author: '익명(글쓴이)',
        likeCount: 0,
        dislikeCount: 0,
        anonymous: false,
        depth: 1,
        parentId: 1,
        createdAt: '04/07 15:20',
      ),
      CommentModel(
        commentId: 3,
        content: 'Sex appeal',
        author: '익명3',
        likeCount: 0,
        dislikeCount: 0,
        anonymous: false,
        depth: 0,
        parentId: null,
        createdAt: '04/07 15:41',
      ),
      CommentModel(
        commentId: 4,
        content: '',
        author: '익명4',
        likeCount: 0,
        dislikeCount: 0,
        anonymous: false,
        depth: 0,
        parentId: null,
        createdAt: '',
      ),
    ],
  };
}