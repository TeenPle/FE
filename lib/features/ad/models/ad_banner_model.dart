class AdBannerModel {
  final int id;
  final String placement;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? linkUrl;
  final bool active;
  final int priority;
  final DateTime? startAt;
  final DateTime? endAt;

  const AdBannerModel({
    required this.id,
    required this.placement,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.linkUrl,
    required this.active,
    required this.priority,
    this.startAt,
    this.endAt,
  });

  factory AdBannerModel.fromJson(Map<String, dynamic> json) {
    return AdBannerModel(
      id: (json['id'] as num).toInt(),
      placement: json['placement'] as String? ?? 'HOME_FEED',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      linkUrl: json['linkUrl'] as String?,
      active: json['active'] as bool? ?? true,
      priority: (json['priority'] as num?)?.toInt() ?? 100,
      startAt: _parseDate(json['startAt']),
      endAt: _parseDate(json['endAt']),
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'placement': placement,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'active': active,
      'priority': priority,
      'startAt': startAt?.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
