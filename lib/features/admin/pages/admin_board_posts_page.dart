import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../models/admin_content_model.dart';
import '../provider/admin_content_provider.dart';

class AdminBoardPostsPage extends ConsumerStatefulWidget {
  final int boardId;
  final String boardTitle;
  final String? schoolName;

  const AdminBoardPostsPage({
    super.key,
    required this.boardId,
    required this.boardTitle,
    this.schoolName,
  });

  @override
  ConsumerState<AdminBoardPostsPage> createState() => _AdminBoardPostsPageState();
}

class _AdminBoardPostsPageState extends ConsumerState<AdminBoardPostsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminPostListProvider(widget.boardId).notifier).load(),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(adminPostListProvider(widget.boardId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPostListProvider(widget.boardId));
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(widget.boardTitle, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.posts.isEmpty
              ? Center(child: Text(state.error!, style: TextStyle(color: c.textMuted)))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(adminPostListProvider(widget.boardId).notifier).load(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index >= state.posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final post = state.posts[index];
                      return _PostTile(
                        post: post,
                        onTap: () => context.push(AppRoutes.adminPostDetail(post.postId)),
                      );
                    },
                  ),
                ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final AdminPostSummaryModel post;
  final VoidCallback onTap;

  const _PostTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(post.postStatus),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.authorLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(fontSize: 11, color: c.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
              if (post.contentPreview.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  post.contentPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, height: 1.4, color: c.textMuted),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _Metric(icon: Icons.visibility_outlined, value: '${post.viewCount}', c: c),
                  _Metric(icon: Icons.thumb_up_alt_outlined, value: '${post.likeCount}', c: c),
                  _Metric(icon: Icons.thumb_down_alt_outlined, value: '${post.dislikeCount}', c: c),
                  _Metric(icon: Icons.mode_comment_outlined, value: '${post.commentCount}', c: c),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVE' => const Color(0xFF2F7D46),
      'HIDDEN' => const Color(0xFFF59E0B),
      _ => context.colors.textMuted,
    };
    final bg = switch (status) {
      'ACTIVE' => const Color(0xFFE8F5E9),
      'HIDDEN' => const Color(0xFFFFFBEB),
      _ => context.colors.subtleBg,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final AppColors c;

  const _Metric({required this.icon, required this.value, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c.iconSecondary),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 11, color: c.textMuted)),
      ],
    );
  }
}
