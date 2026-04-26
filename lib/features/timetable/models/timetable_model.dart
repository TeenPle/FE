class TimetablePeriod {
  final String date;
  final int dayOfWeek; // 1=월 ~ 5=금
  final int period;   // 교시
  final String subject;

  const TimetablePeriod({
    required this.date,
    required this.dayOfWeek,
    required this.period,
    required this.subject,
  });

  factory TimetablePeriod.fromJson(Map<String, dynamic> json) {
    return TimetablePeriod(
      date: json['date'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as int? ?? 0,
      period: json['period'] as int? ?? 0,
      subject: json['subject'] as String? ?? '',
    );
  }
}

class TimetableWeek {
  final String grade;
  final String classRoom;
  final List<TimetablePeriod> periods;
  final bool neisAvailable;

  const TimetableWeek({
    required this.grade,
    required this.classRoom,
    required this.periods,
    this.neisAvailable = true,
  });

  factory TimetableWeek.fromJson(Map<String, dynamic> json) {
    final periods = (json['periods'] as List<dynamic>? ?? [])
        .map((e) => TimetablePeriod.fromJson(e as Map<String, dynamic>))
        .toList();
    return TimetableWeek(
      grade: json['grade'] as String? ?? '',
      classRoom: json['classRoom'] as String? ?? '',
      periods: periods,
      neisAvailable: json['neisAvailable'] as bool? ?? true,
    );
  }

  // [dayOfWeek][period] → subject 빠른 조회용 맵
  Map<String, String> get subjectMap {
    return {
      for (final p in periods) '${p.dayOfWeek}_${p.period}': p.subject,
    };
  }
}
