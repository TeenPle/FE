class ReactionRequest {
  final String targetType;
  final int targetId;
  final String action;

  const ReactionRequest({
    required this.targetType,
    required this.targetId,
    required this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetType': targetType,
      'targetId': targetId,
      'action': action,
    };
  }
}