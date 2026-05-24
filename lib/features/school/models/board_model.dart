class BoardModel {
  final int id;
  final String title;
  final String description;
  final bool active;
  final String scope;
  final String? type;
  final bool defaultBoard;
  final int sortOrder;

  const BoardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.active,
    this.scope = 'SCHOOL',
    this.type,
    this.defaultBoard = false,
    this.sortOrder = 999,
  });

  bool get isRegion => scope == 'REGION';

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      scope: json['scope'] as String? ?? 'SCHOOL',
      type: json['type'] as String?,
      defaultBoard: json['defaultBoard'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 999,
    );
  }
}
