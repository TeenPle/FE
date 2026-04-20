class BoardModel {
  final int id;
  final String title;
  final String description;
  final bool active;

  const BoardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.active,
  });

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }
}