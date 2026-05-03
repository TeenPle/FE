import 'dart:convert';

class DDayModel {
  final String id;
  final String label;
  final DateTime targetDate;

  const DDayModel({
    required this.id,
    required this.label,
    required this.targetDate,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  String get dDayLabel {
    final d = daysRemaining;
    if (d == 0) return 'D-Day';
    if (d > 0) return 'D-$d';
    return 'D+${-d}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'targetDate': targetDate.toIso8601String(),
      };

  factory DDayModel.fromJson(Map<String, dynamic> json) => DDayModel(
        id: json['id'] as String,
        label: json['label'] as String,
        targetDate: DateTime.parse(json['targetDate'] as String),
      );

  static String encodeList(List<DDayModel> list) =>
      jsonEncode(list.map((d) => d.toJson()).toList());

  static List<DDayModel> decodeList(String raw) =>
      (jsonDecode(raw) as List)
          .map((e) => DDayModel.fromJson(e as Map<String, dynamic>))
          .toList();

  DDayModel copyWith({String? id, String? label, DateTime? targetDate}) =>
      DDayModel(
        id: id ?? this.id,
        label: label ?? this.label,
        targetDate: targetDate ?? this.targetDate,
      );
}
