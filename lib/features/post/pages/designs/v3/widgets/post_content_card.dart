import 'package:flutter/material.dart';
import '../../../../models/post_detail.dart';
import '../../../widgets/linkable_text.dart';

// V3: 토스/카카오 소프트 카드 스타일 — 그림자 카드, 큰 아바타, 테마색 accent
class PostContentCardV3 extends StatelessWidget {
  final PostDetail post;

  const PostContentCardV3({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8BBFE0).withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PostMetaRow(post: post),
            const SizedBox(height: 16),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            LinkableText(
              text: post.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.78,
                color: Color(0xFF374151),
              ),
            ),
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              _MediaGallery(mediaUrls: post.mediaUrls),
            ],
          ],
        ),
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
        borderRadius: BorderRadius.circular(12),
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
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCCE4F7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, size: 16,
                color: Color(0xFF3A9BD5)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(_filename, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF2980B9),
                      fontWeight: FontWeight.w600)),
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
      children: [
        // 큰 원형 아바타
        Container(
          width: 46, height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFCEE8F5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded,
              color: Color(0xFF3A9BD5), size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.displayAuthorName,
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827))),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (post.createdAt.isNotEmpty)
                    const Text('방금 전',
                        style: TextStyle(fontSize: 12,
                            color: Color(0xFF9CA3AF))),
                  const SizedBox(width: 6),
                  Text('조회 ${post.viewCount}',
                      style: const TextStyle(fontSize: 12,
                          color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
        ),
        if (post.postStatus.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F9FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(post.postStatus,
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A7FC1))),
          ),
      ],
    );
  }
}
