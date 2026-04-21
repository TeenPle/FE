class PostMediaItem {
  final int mediaId;
  final String url;
  final String mediaType;

  const PostMediaItem({
    required this.mediaId,
    required this.url,
    required this.mediaType,
  });

  factory PostMediaItem.fromJson(Map<String, dynamic> json) {
    return PostMediaItem(
      mediaId: (json['mediaId'] as num).toInt(),
      url: json['url'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? '',
    );
  }

  bool get isImage {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        mediaType.toUpperCase() == 'IMAGE';
  }
}
