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
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _MediaGallery(mediaUrls: post.mediaUrls),
          ],
        ],
      ),
    );
  }
}

/// 첨부 미디어 갤러리
class _MediaGallery extends StatelessWidget {
  final List<String> mediaUrls;

  const _MediaGallery({required this.mediaUrls});

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
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
          Container(
            height: 1,
            color: const Color(0xFFEEF3F7),
            margin: const EdgeInsets.only(bottom: 14),
          ),
          // 이미지가 1개면 전체 너비, 여러 개면 가로 스크롤
          if (imageUrls.length == 1)
            _SingleImage(url: imageUrls.first)
          else
            _ImageRow(urls: imageUrls),
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
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        ),
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
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _openImageViewer(context, urls[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                urls[i],
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 160,
                  height: 160,
                  color: const Color(0xFFF0F4F8),
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: Color(0xFF9AA7B2),
                    size: 32,
                  ),
                ),
              ),
            ),
          );
        },
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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD6DEE7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_rounded,
              size: 18,
              color: Color(0xFF5A8EA8),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF3D6A85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _defaultAvatar() {
  return Container(
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
  );
}

Widget _imagePlaceholder() {
  return Container(
    height: 200,
    color: const Color(0xFFF0F4F8),
    child: const Center(
      child: Icon(Icons.broken_image_rounded, color: Color(0xFF9AA7B2), size: 36),
    ),
  );
}

void _openImageViewer(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_rounded,
                    color: Colors.white54, size: 60),
              ),
            ),
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
    final profileUrl = post.authorProfileImageUrl;
    final showNetworkAvatar = !post.anonymous &&
        profileUrl != null &&
        profileUrl.isNotEmpty;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: showNetworkAvatar
              ? Image.network(
                  profileUrl!,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultAvatar(),
                )
              : _defaultAvatar(),
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