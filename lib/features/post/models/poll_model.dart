class PollOptionModel {
  final int optionId;
  final String text;
  final int voteCount;
  final int percentage;
  final bool selectedByMe;

  const PollOptionModel({
    required this.optionId,
    required this.text,
    required this.voteCount,
    required this.percentage,
    required this.selectedByMe,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      optionId: (json['optionId'] as num).toInt(),
      text: json['text'] as String? ?? '',
      voteCount: json['voteCount'] != null ? (json['voteCount'] as num).toInt() : 0,
      percentage: json['percentage'] != null ? (json['percentage'] as num).toInt() : 0,
      selectedByMe: json['selectedByMe'] as bool? ?? false,
    );
  }
}

class PollModel {
  final int pollId;
  final int totalParticipants;
  final bool hasVoted;
  final int? selectedOptionId;
  final List<PollOptionModel> options;

  const PollModel({
    required this.pollId,
    required this.totalParticipants,
    required this.hasVoted,
    this.selectedOptionId,
    required this.options,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      pollId: (json['pollId'] as num).toInt(),
      totalParticipants: json['totalParticipants'] != null
          ? (json['totalParticipants'] as num).toInt()
          : 0,
      hasVoted: json['hasVoted'] as bool? ?? false,
      selectedOptionId: json['selectedOptionId'] != null
          ? (json['selectedOptionId'] as num).toInt()
          : null,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => PollOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
