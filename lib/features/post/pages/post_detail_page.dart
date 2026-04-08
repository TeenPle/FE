import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../form/comment_input_bar.dart';
import '../models/comment_model.dart';
import '../provider/post_detail_providers.dart';
import 'widgets/comment_item.dart';
import 'widgets/post_action_bar.dart';
import 'widgets/post_content_card.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailPage({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(postDetailProvider(widget.postId).notifier).loadPostDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailProvider(widget.postId));
    final notifier = ref.read(postDetailProvider(widget.postId).notifier);
    final post = state.post;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF3F9FF),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '자유게시판',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            SizedBox(height: 2),
            Text(
              '광운대',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7D8790),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'report') {
                debugPrint('신고하기');
              } else if (value == 'chat') {
                debugPrint('채팅하기');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'report',
                child: Text('신고하기'),
              ),
              PopupMenuItem(
                value: 'chat',
                child: Text('채팅하기'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CommentInputBar(
        anonymous: state.commentAnonymous,
        isSubmitting: state.isSubmittingComment,
        replyingToCommentId: state.replyingToCommentId,
        onAnonymousChanged: notifier.toggleCommentAnonymous,
        onSubmit: notifier.submitComment,
        onCancelReply: notifier.cancelReply,
      ),
      body: state.isLoading && post == null
          ? const Center(child: CircularProgressIndicator())
          : post == null
          ? Center(
        child: Text(
          state.errorMessage ?? '게시글을 불러오지 못했습니다.',
          style: const TextStyle(color: Color(0xFF222222)),
        ),
      )
          : ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          PostContentCard(post: post),
          const Divider(
            height: 1,
            thickness: 0.7,
            color: Color(0xFFDCE7F0),
          ),
          PostActionBar(
            likeCount: post.likeCount,
            commentCount: post.comments.length,
            likedByMe: state.likedByMe,
            onLikeTap: notifier.toggleLike,
            onShareTap: () {
              debugPrint('share post: ${post.postId}');
            },
          ),
          const Divider(
            height: 1,
            thickness: 0.7,
            color: Color(0xFFDCE7F0),
          ),
          ..._buildCommentWidgets(
            comments: state.comments,
            onReplyTap: (commentId, isReply) {
              notifier.startReply(commentId, isReply: isReply);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCommentWidgets({
    required List<CommentModel> comments,
    required void Function(int commentId, bool isReply) onReplyTap,
  }) {
    final parents = comments.where((e) => e.parentId == null).toList();

    return parents.map((parent) {
      final replies = comments.where((e) => e.parentId == parent.commentId).toList();

      return CommentItem(
        comment: parent,
        replies: replies,
        onReplyTap: () => onReplyTap(parent.commentId, false),
        onLikeTap: () {
          debugPrint('comment like: ${parent.commentId}');
        },
      );
    }).toList();
  }
}