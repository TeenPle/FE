import 'package:flutter/material.dart';
import '../../models/post_detail.dart';

class PostContentCard extends StatelessWidget {
  final PostDetail post;

  const PostContentCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostMetaRow(post: post),
          const SizedBox(height: 18),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: Color(0xFF2F3740),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostMetaRow extends StatelessWidget {
  final PostDetail post;

  const _PostMetaRow({
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFF8EA2B5),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.displayAuthorName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (post.createdAt.isNotEmpty)
                    const _MetaText('방금 전'),
                  _MetaText('조회 ${post.viewCount}'),
                  _MetaText(post.postStatus.isEmpty ? '일반글' : post.postStatus),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaText extends StatelessWidget {
  final String value;

  const _MetaText(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF7D8790),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}