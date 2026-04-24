import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/profile_provider.dart';

class MyCommentsPage extends ConsumerWidget {
  const MyCommentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(myCommentsProvider(0));

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: const Text(
          '내가 쓴 댓글',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: commentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(color: Color(0xFF7D8790)),
          ),
        ),
        data: (comments) {
          if (comments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 52, color: Color(0xFFCDD5DB)),
                  SizedBox(height: 12),
                  Text(
                    '아직 쓴 댓글이 없어요.',
                    style: TextStyle(fontSize: 15, color: Color(0xFF9AA7B2)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final comment = comments[i];
              return GestureDetector(
                onTap: () => context.push('/post/${comment.postId}'),
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
                      // 원글 제목
                      Row(
                        children: [
                          const Icon(Icons.article_outlined,
                              size: 13, color: Color(0xFF9AA7B2)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              comment.postTitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9AA7B2),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comment.content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF2F3740),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.thumb_up_outlined,
                              size: 13, color: Color(0xFF9AA7B2)),
                          const SizedBox(width: 3),
                          Text(
                            '${comment.likeCount}',
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
