class ProfileModel {
  final int id;
  final String nickname;
  final String email;
  final String profileImageUrl;
  final String schoolName;
  final String grade;
  final String gender;
  final bool verified;
  final bool phoneVerified;

  const ProfileModel({
    required this.id,
    required this.nickname,
    required this.email,
    required this.profileImageUrl,
    required this.schoolName,
    required this.grade,
    required this.gender,
    required this.verified,
    required this.phoneVerified,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: (json['id'] as num).toInt(),
      nickname: json['nickname'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
    );
  }

  String get gradeLabel {
    switch (grade) {
      case 'FIRST': return '1학년';
      case 'SECOND': return '2학년';
      case 'THIRD': return '3학년';
      case 'GRADUATED': return '졸업생';
      default: return grade;
    }
  }

  String get genderLabel {
    switch (gender) {
      case 'MALE': return '남성';
      case 'FEMALE': return '여성';
      default: return gender;
    }
  }
}
