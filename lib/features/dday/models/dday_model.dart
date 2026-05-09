import 'dart:convert';

import 'package:flutter/material.dart';

const Map<String, IconData> ddayIconMap = {
  'event': Icons.event_rounded,
  'school': Icons.school_rounded,
  'book': Icons.menu_book_rounded,
  'edit': Icons.edit_rounded,
  'run': Icons.directions_run_rounded,
  'celebration': Icons.celebration_rounded,
  'flight': Icons.flight_takeoff_rounded,
  'favorite': Icons.favorite_rounded,
  'cake': Icons.cake_rounded,
  'flag': Icons.flag_rounded,
  'trophy': Icons.emoji_events_rounded,
  'timer': Icons.timer_rounded,
  'science': Icons.science_rounded,
  'music': Icons.music_note_rounded,
  'sports': Icons.sports_soccer_rounded,
  'star': Icons.star_rounded,
};

class DDayModel {
  final String id;
  final String label;
  final DateTime targetDate;
  final String iconName;

  const DDayModel({
    required this.id,
    required this.label,
    required this.targetDate,
    this.iconName = 'event',
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
        'iconName': iconName,
      };

  factory DDayModel.fromJson(Map<String, dynamic> json) => DDayModel(
        id: json['id'] as String,
        label: json['label'] as String,
        targetDate: DateTime.parse(json['targetDate'] as String),
        iconName: json['iconName'] as String? ?? 'event',
      );

  static String encodeList(List<DDayModel> list) =>
      jsonEncode(list.map((d) => d.toJson()).toList());

  static List<DDayModel> decodeList(String raw) =>
      (jsonDecode(raw) as List)
          .map((e) => DDayModel.fromJson(e as Map<String, dynamic>))
          .toList();

  DDayModel copyWith({
    String? id,
    String? label,
    DateTime? targetDate,
    String? iconName,
  }) => DDayModel(
        id: id ?? this.id,
        label: label ?? this.label,
        targetDate: targetDate ?? this.targetDate,
        iconName: iconName ?? this.iconName,
      );
}
