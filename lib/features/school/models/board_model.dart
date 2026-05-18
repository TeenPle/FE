class BoardModel {
  final int id;
  final String title;
  final String description;
  final bool active;
  // 게시판 범위: 'SCHOOL'(학교 게시판) 또는 'REGION'(지역 게시판)
  final String scope;

  const BoardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.active,
    this.scope = 'SCHOOL',
  });

  // 지역 게시판 여부
  bool get isRegion => scope == 'REGION';

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      scope: json['scope'] as String? ?? 'SCHOOL',
    );
  }
}
