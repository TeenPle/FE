/// 학교 검색 결과 1개를 담는 모델
class SchoolModel {
  final int id;
  final String name;
  final int? regionId;
  final String? regionName;
  final bool hasDuplicateName;

  const SchoolModel({
    required this.id,
    required this.name,
    this.regionId,
    this.regionName,
    this.hasDuplicateName = false,
  });

  /// JSON -> 모델 변환
  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      regionId: (json['regionId'] as num?)?.toInt(),
      regionName: json['regionName'] as String?,
    );
  }

  SchoolModel withDuplicateNameStatus(bool value) {
    return SchoolModel(
      id: id,
      name: name,
      regionId: regionId,
      regionName: regionName,
      hasDuplicateName: value,
    );
  }
}

/// 이름이 완전히 같은 학교가 검색 결과에 둘 이상 있을 때만 중복으로 표시한다.
///
/// 지역명은 동명 학교를 구분할 때만 필요하므로, 이 값을 화면 표시 기준으로 사용한다.
List<SchoolModel> markDuplicateSchoolNames(Iterable<SchoolModel> schools) {
  final schoolList = schools.toList(growable: false);
  final nameCounts = <String, int>{};

  for (final school in schoolList) {
    nameCounts.update(school.name, (count) => count + 1, ifAbsent: () => 1);
  }

  return schoolList
      .map(
        (school) => school.withDuplicateNameStatus(
          (nameCounts[school.name] ?? 0) > 1,
        ),
      )
      .toList(growable: false);
}
