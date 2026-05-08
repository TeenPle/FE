import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../models/admin_content_model.dart';
import '../provider/admin_content_provider.dart';

class AdminPostDetailPage extends ConsumerStatefulWidget {
  final int postId;

  const AdminPostDetailPage({super.key, required this.postId});

  @override
  ConsumerState<AdminPostDetailPage> createState() => _AdminPostDetailPageState();
}

class _AdminPostDetailPageState extends ConsumerState<AdminPostDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminPostDetailProvider(widget.postId).notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPostDetailProvider(widget.postId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        title: const Text('게시글 모더레이션', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.post == null
              ? Center(child: Text(state.error!))
              : state.post == null
                  ? const SizedBox()
                  : _PostDetailBody(post: state.post!),
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  final AdminPostDetailModel post;

  const _PostDetailBody({required this.post});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(post.postStatus),
                  const Spacer(),
                  Text(_formatDate(post.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                post.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827), height: 1.25),
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.6),
              ),
              if (post.mediaList.isNotEmpty) ...[
                const SizedBox(height: 16),
                _MediaGrid(mediaList: post.mediaList),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InfoChip(Icons.school_outlined, post.schoolName ?? post.regionName ?? '학교/지역 없음'),
                  _InfoChip(Icons.dashboard_outlined, post.boardTitle),
                  _InfoChip(Icons.person_outline, post.authorLabel),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                children: [
                  _Metric(icon: Icons.visibility_outlined, value: '조회 ${post.viewCount}'),
                  _Metric(icon: Icons.thumb_up_alt_outlined, value: '공감 ${post.likeCount}'),
                  _Metric(icon: Icons.thumb_down_alt_outlined, value: '비공감 ${post.dislikeCount}'),
                  _Metric(icon: Icons.mode_comment_outlined, value: '댓글 ${post.commentCount}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '운영 액션',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F2933)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.adminUserHistory(post.authorUserId),
                        extra: {'nickname': post.authorLabel},
                      ),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('작성자 이력'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF426C82),
                        side: const BorderSide(color: Color(0xFFBBD3DF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '댓글 ${post.comments.length}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F2933)),
              ),
              const SizedBox(height: 12),
              if (post.comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('댓글이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8))),
                )
              else
                ...post.comments.map((comment) => _CommentTile(comment: comment)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<AdminMediaModel> mediaList;

  const _MediaGrid({required this.mediaList});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mediaList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final media = mediaList[index];
        if (!media.isImage) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF64748B)),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(media.url, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final AdminCommentModel comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: comment.depth > 0 ? 18 : 0, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: comment.depth > 0 ? const Color(0xFFF8FAFC) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.authorLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
              ),
              _StatusBadge(comment.commentStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.content, style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.45)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _Metric(icon: Icons.thumb_up_alt_outlined, value: '${comment.likeCount}'),
              _Metric(icon: Icons.thumb_down_alt_outlined, value: '${comment.dislikeCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVE' => const Color(0xFF2F7D46),
      'HIDDEN' => const Color(0xFFF59E0B),
      'DELETED' => const Color(0xFF64748B),
      _ => const Color(0xFF64748B),
    };
    final bg = switch (status) {
      'ACTIVE' => const Color(0xFFE8F5E9),
      'HIDDEN' => const Color(0xFFFFFBEB),
      'DELETED' => const Color(0xFFF1F5F9),
      _ => const Color(0xFFF1F5F9),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;

  const _Metric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }
}
