import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/profile_provider.dart';

class MyLikedPostsPage extends ConsumerWidget {
  const MyLikedPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(myLikedPostsProvider(0));

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: const Text(
          '내가 공감한 글',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(color: Color(0xFF7D8790)),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thumb_up_outlined,
                      size: 52, color: Color(0xFFCDD5DB)),
                  SizedBox(height: 12),
                  Text(
                    '아직 공감한 글이 없어요.',
                    style: TextStyle(fontSize: 15, color: Color(0xFF9AA7B2)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final post = posts[i];
              return GestureDetector(
                onTap: () => context.push('/post/${post.postId}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6EDF3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.preview,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF6E7B87),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.thumb_up_rounded,
                              size: 14, color: Color(0xFF14A3F7)),
                          const SizedBox(width: 3),
                          Text(
                            '${post.likeCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF14A3F7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 14, color: Color(0xFF9AA7B2)),
                          const SizedBox(width: 3),
                          Text(
                            '${post.commentCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9AA7B2),
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
        },
      ),
    );
  }
}
