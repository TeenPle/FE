class BoardDisplayProfileModel {
  final int boardId;
  final String boardName;
  final String displayName;
  final String profileImageUrl;
  final DateTime? lastChangedAt;
  final DateTime? nextChangeAvailableAt;
  final bool changeAvailable;
  final int remainingDays;

  const BoardDisplayProfileModel({
    required this.boardId,
    required this.boardName,
    required this.displayName,
    required this.profileImageUrl,
    this.lastChangedAt,
    this.nextChangeAvailableAt,
    required this.changeAvailable,
    required this.remainingDays,
  });

  factory BoardDisplayProfileModel.fromJson(Map<String, dynamic> json) {
    return BoardDisplayProfileModel(
      boardId: (json['boardId'] as num).toInt(),
      boardName: json['boardName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      lastChangedAt: json['lastChangedAt'] != null
          ? DateTime.tryParse(json['lastChangedAt'] as String)
          : null,
      nextChangeAvailableAt: json['nextChangeAvailableAt'] != null
          ? DateTime.tryParse(json['nextChangeAvailableAt'] as String)
          : null,
      changeAvailable: json['changeAvailable'] as bool? ?? false,
      remainingDays: (json['remainingDays'] as num?)?.toInt() ?? 0,
    );
  }
}
