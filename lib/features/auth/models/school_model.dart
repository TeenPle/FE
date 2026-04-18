/// 학교 검색 결과 1개를 담는 모델
class SchoolModel {
  final int id;
  final String name;

  const SchoolModel({
    required this.id,
    required this.name,
  });

  /// JSON -> 모델 변환
  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}