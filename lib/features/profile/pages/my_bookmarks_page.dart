import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../provider/profile_provider.dart';

class MyBookmarksPage extends ConsumerStatefulWidget {
  const MyBookmarksPage({super.key});

  @override
  ConsumerState<MyBookmarksPage> createState() => _MyBookmarksPageState();
}

class _MyBookmarksPageState extends ConsumerState<MyBookmarksPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myBookmarksNotifierProvider.notifier).load();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(myBookmarksNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myBookmarksNotifierProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        title: Text(
          '내 북마크',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(MyBookmarksState state) {
    final c = context.colors;

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 52, color: c.iconMuted),
            const SizedBox(height: 12),
            Text(
              '아직 북마크한 글이 없어요.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i == state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final post = state.items[i];
        final cc = ctx.colors;
        return GestureDetector(
          onTap: () => ctx.push('/post/${post.postId}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cc.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cc.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.boardTitle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cc.tintBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.boardTitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14A3F7),
                        ),
                      ),
                    ),
                  ),
                Text(
                  post.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cc.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  post.preview,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    height: 1.5,
                    color: cc.iconOnCard,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Chip(
                      icon: Icons.bookmark_rounded,
                      label: '북마크',
                      color: const Color(0xFFF5A623),
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.thumb_up_outlined,
                      label: '${post.likeCount}',
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${post.commentCount}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 11,
            color: c,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
