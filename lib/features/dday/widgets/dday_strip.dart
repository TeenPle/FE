import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../models/dday_model.dart';
import '../provider/dday_provider.dart';

class DDayStrip extends ConsumerWidget {
  const DDayStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ddays = ref.watch(ddayProvider);

    final sorted = [...ddays]
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'D-DAY',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF229BF3),
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(AppRoutes.ddaySettings),
                child: const Row(
                  children: [
                    Text(
                      '전체 보기',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B0B0B),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Color(0xFF0B0B0B),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < sorted.length; i++) ...[
                    _DDayChip(dday: sorted[i]),
                    const SizedBox(width: 7),
                  ],
                  const _AddChip(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DDayChip extends StatelessWidget {
  final DDayModel dday;

  const _DDayChip({required this.dday});

  Color get _accentColor {
    final d = dday.daysRemaining;
    if (d == 0) return const Color(0xFFE05C7B);
    if (d > 0 && d <= 7) return const Color(0xFFFF6B35);
    if (d > 0) return const Color(0xFF4A67F2);
    return const Color(0xFF9AA7B2);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    final icon = ddayIconMap[dday.iconName] ?? Icons.event_rounded;
    final dateStr =
        '${dday.targetDate.year.toString().substring(2)}.${dday.targetDate.month.toString().padLeft(2, '0')}.${dday.targetDate.day.toString().padLeft(2, '0')}';

    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6EAFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 아이콘 + 제목
          Row(
            children: [
              Icon(icon, size: 12, color: accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dday.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F252B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // 날짜 + D-day 숫자
          Row(
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9AA7B2),
                ),
              ),
              const Spacer(),
              Text(
                dday.dDayLabel,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.ddaySettings),
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FCFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBE7FF)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 16, color: Color(0xFF229BF3)),
            SizedBox(height: 3),
            Text(
              '추가',
              style: TextStyle(
                fontSize: 9,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF229BF3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
