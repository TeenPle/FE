/// epoch ms → DateTime (로컬 타임존, 타임존 무관하게 정확)
DateTime? parseCreatedAtMs(int? ms) =>
    ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

/// 목록용: 방금 전 / n분 전 / hh:mm / mm/dd
String timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';

  final todayMidnight = DateTime(now.year, now.month, now.day);
  if (dt.isAfter(todayMidnight)) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}

/// 상세 페이지용: mm/dd hh:mm
String formatDateTime(DateTime dt) {
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$m/$d $h:$min';
}
