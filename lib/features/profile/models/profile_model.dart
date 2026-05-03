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
  final int myPostCount;
  final int myCommentCount;
  final DateTime? nicknameChangedAt;

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
    this.myPostCount = 0,
    this.myCommentCount = 0,
    this.nicknameChangedAt,
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
      myPostCount: (json['myPostCount'] as num?)?.toInt() ?? 0,
      myCommentCount: (json['myCommentCount'] as num?)?.toInt() ?? 0,
      nicknameChangedAt: json['nicknameChangedAt'] != null
          ? DateTime.tryParse(json['nicknameChangedAt'] as String)
          : null,
    );
  }

  bool get canChangeNickname {
    if (nicknameChangedAt == null) return true;
    return DateTime.now().difference(nicknameChangedAt!).inDays >= 30;
  }

  /// 변경 가능까지 남은 일수 (이미 가능하면 0)
  int get daysUntilNicknameChange {
    if (nicknameChangedAt == null) return 0;
    final nextAllowed = nicknameChangedAt!.add(const Duration(days: 30));
    final remaining = nextAllowed.difference(DateTime.now()).inDays + 1;
    return remaining.clamp(0, 30);
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
