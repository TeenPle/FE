import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../models/post_detail.dart';
import 'linkable_text.dart';

class PostContentCard extends StatelessWidget {
  final PostDetail post;

  const PostContentCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _PostMetaRow(post: post),
        const SizedBox(height: 20),
        Text(
          post.title,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
            height: 1.3,
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 16),
          color: c.dividerBlue,
        ),
        LinkableText(
          text: post.content,
          style: TextStyle(
            fontSize: 14,
            height: 1.72,
            color: c.textBody,
            letterSpacing: 0,
          ),
        ),
        if (post.mediaUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          _MediaGallery(mediaUrls: post.mediaUrls),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

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
    final c = context.colors;
    final imageUrls = mediaUrls.where(_isImageUrl).toList();
    final fileUrls = mediaUrls.where((u) => !_isImageUrl(u)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrls.isNotEmpty) ...[
          Container(
            height: 1,
            color: c.dividerBlue,
            margin: const EdgeInsets.only(bottom: 14),
          ),
          if (imageUrls.length == 1)
            _SingleImage(url: imageUrls.first)
          else
            _ImageRow(urls: imageUrls, placeholderColor: c.borderSubtle),
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
        child: CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => _imagePlaceholder(context),
          errorWidget: (_, __, ___) => _imagePlaceholder(context),
        ),
      ),
    );
  }
}

class _ImageRow extends StatelessWidget {
  final List<String> urls;
  final Color placeholderColor;
  const _ImageRow({required this.urls, required this.placeholderColor});

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
              child: CachedNetworkImage(
                imageUrl: urls[i],
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 160,
                  height: 160,
                  color: placeholderColor,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 160,
                  height: 160,
                  color: placeholderColor,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: context.colors.iconSecondary,
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
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.subtleBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              size: 18,
              color: c.iconOnCard,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: c.textSecondary,
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

Widget _defaultAvatar(BuildContext context) {
  final c = context.colors;
  return Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: c.tintBg,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(Icons.person_rounded, color: c.iconSecondary, size: 24),
  );
}

Widget _imagePlaceholder(BuildContext context) {
  final c = context.colors;
  return Container(
    height: 200,
    color: c.borderSubtle,
    child: Center(
      child: Icon(Icons.broken_image_rounded, color: c.iconSecondary, size: 36),
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
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(
                    color: Colors.white54, strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => const Center(
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

String _formatDetailTime(int? ms) {
  final dt = parseCreatedAtMs(ms);
  if (dt == null) return '';
  return formatDateTime(dt);
}

class _PostMetaRow extends StatelessWidget {
  final PostDetail post;

  const _PostMetaRow({required this.post});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profileUrl = post.authorProfileImageUrl;
    final showNetworkAvatar =
        !post.anonymous && profileUrl != null && profileUrl.isNotEmpty;

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
                  errorBuilder: (ctx, _, __) => _defaultAvatar(ctx),
                )
              : _defaultAvatar(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.displayAuthorName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  _MetaText('조회 ${post.viewCount}', color: c.textMuted),
                  if (post.createdAtMs != null) ...[
                    const SizedBox(width: 6),
                    _MetaText('·', color: c.textMuted),
                    const SizedBox(width: 6),
                    _MetaText(
                      _formatDetailTime(post.createdAtMs),
                      color: c.textMuted,
                    ),
                  ],
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
  final Color color;

  const _MetaText(this.value, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
