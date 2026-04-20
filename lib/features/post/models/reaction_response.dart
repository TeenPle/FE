class ReactionResponse {
  final int targetId;
  final String targetType;
  final bool liked;
  final bool disliked;
  final bool applied;
  final int likeCount;
  final int dislikeCount;

  const ReactionResponse({
    required this.targetId,
    required this.targetType,
    required this.liked,
    required this.disliked,
    required this.applied,
    required this.likeCount,
    required this.dislikeCount,
  });

  factory ReactionResponse.fromJson(Map<String, dynamic> json) {
    return ReactionResponse(
      targetId: (json['targetId'] as num).toInt(),
      targetType: json['targetType'] as String? ?? '',
      liked: json['liked'] as bool? ?? false,
      disliked: json['disliked'] as bool? ?? false,
      applied: json['applied'] as bool? ?? false,
      likeCount: json['likeCount'] != null ? (json['likeCount'] as num).toInt() : 0,
      dislikeCount: json['dislikeCount'] != null ? (json['dislikeCount'] as num).toInt() : 0,
    );
  }
}