import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../provider/profile_provider.dart';

class MyLikedPostsPage extends ConsumerStatefulWidget {
  const MyLikedPostsPage({super.key});

  @override
  ConsumerState<MyLikedPostsPage> createState() => _MyLikedPostsPageState();
}

class _MyLikedPostsPageState extends ConsumerState<MyLikedPostsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myLikedPostsNotifierProvider.notifier).load();
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
      ref.read(myLikedPostsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myLikedPostsNotifierProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        title: Text(
          '내가 공감한 글',
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

  Widget _buildBody(MyLikedPostsState state) {
    final c = context.colors;

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up_outlined, size: 52, color: c.iconMuted),
            const SizedBox(height: 12),
            Text(
              '아직 공감한 글이 없어요.',
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
      separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.thumb_up_rounded,
                      size: 14,
                      color: Color(0xFF14A3F7),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${post.likeCount}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: Color(0xFF14A3F7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 14,
                      color: cc.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${post.commentCount}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: cc.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
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
