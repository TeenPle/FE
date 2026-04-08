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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE7F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
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
                    const SizedBox(height: 2),
                    Text(
                      post.createdAt,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7D8790),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 17,
              height: 1.6,
              color: Color(0xFF333A42),
            ),
          ),
        ],
      ),
    );
  }
}