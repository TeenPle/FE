import 'package:flutter/material.dart';
import '../../../../models/post_detail.dart';

// V1: 에브리타임/네이버카페 스타일 — 테마색 배경 + 풀너비 흰 블록, 원형 아바타
class PostContentCardV1 extends StatelessWidget {
  final PostDetail post;

  const PostContentCardV1({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostMetaRow(post: post),
          const SizedBox(height: 14),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.75,
              color: Color(0xFF2F3740),
            ),
          ),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _MediaGallery(mediaUrls: post.mediaUrls),
          ],
        ],
      ),
    );
  }
}

class _MediaGallery extends StatelessWidget {
  final List<String> mediaUrls;
  const _MediaGallery({required this.mediaUrls});

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
        lower.endsWith('.png') || lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = mediaUrls.where(_isImageUrl).toList();
    final fileUrls = mediaUrls.where((u) => !_isImageUrl(u)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrls.isNotEmpty) ...[
          Container(height: 1, color: const Color(0xFFEEF3F7),
              margin: const EdgeInsets.only(bottom: 14)),
          if (imageUrls.length == 1) _SingleImage(url: imageUrls.first)
          else _ImageRow(urls: imageUrls),
        ],
        if (fileUrls.isNotEmpty) ...[
          if (imageUrls.isNotEmpty) const SizedBox(height: 10),
          ...fileUrls.map((url) => _FileAttachmentChip(url: url)),
        ],
      ],
    );
  }
}

class _SingleImage extends StatelessWidget {
  final String url;
  const _SingleImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(url, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder()),
      ),
    );
  }
}

class _ImageRow extends StatelessWidget {
  final List<String> urls;
  const _ImageRow({required this.urls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _openImageViewer(context, urls[i]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(urls[i], width: 160, height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 160, height: 160,
                  color: const Color(0xFFF0F4F8),
                  child: const Icon(Icons.broken_image_rounded,
                      color: Color(0xFF9AA7B2), size: 32),
                )),
          ),
        ),
      ),
    );
  }
}

class _FileAttachmentChip extends StatelessWidget {
  final String url;
  const _FileAttachmentChip({required this.url});

  String get _filename {
    final decoded = Uri.decodeFull(url);
    return decoded.split('/').last.split('?').first;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD6DEE7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, size: 16,
                color: Color(0xFF5A8EA8)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(_filename, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF3D6A85), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _imagePlaceholder() => Container(
  height: 200, color: const Color(0xFFF0F4F8),
  child: const Center(child: Icon(Icons.broken_image_rounded,
      color: Color(0xFF9AA7B2), size: 36)),
);

void _openImageViewer(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: SizedBox(
          width: double.infinity, height: double.infinity,
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white54, size: 60))),
          ),
        ),
      ),
    ),
  );
}

class _PostMetaRow extends StatelessWidget {
  final PostDetail post;
  const _PostMetaRow({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 원형 아바타
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFDDEEF9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded,
              color: Color(0xFF7DA9C8), size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.displayAuthorName,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: Color(0xFF111111))),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (post.createdAt.isNotEmpty)
                    const Text('방금 전',
                        style: TextStyle(fontSize: 12,
                            color: Color(0xFF95A3AF),
                            fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  Text('조회 ${post.viewCount}',
                      style: const TextStyle(fontSize: 12,
                          color: Color(0xFF95A3AF),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
        if (post.postStatus.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F9FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(post.postStatus,
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: Color(0xFF3A9BD5))),
          ),
      ],
    );
  }
}
