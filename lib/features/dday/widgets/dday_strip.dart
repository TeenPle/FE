import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dday_model.dart';
import '../provider/dday_provider.dart';

class DDayStrip extends ConsumerWidget {
  const DDayStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final ddays = ref.watch(ddayProvider);

    final sorted = [...ddays]
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler:
            MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.0),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sorted.isEmpty)
              GestureDetector(
                onTap: () => context.push(AppRoutes.ddaySettings),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: c.textDisabled,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '중요한 날을 D-Day로 기록해보세요',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.0,
                            fontWeight: FontWeight.w500,
                            color: c.textDisabled,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.ddaySettings),
                        child: Row(
                          children: [
                            Text(
                              '전체 보기',
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.0,
                                fontWeight: FontWeight.w600,
                                color: c.textMuted,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: c.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
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
                      const SizedBox(width: 4),
                      _ViewAllChip(),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
    final c = context.colors;
    final accent = _accentColor;
    final icon = ddayIconMap[dday.iconName] ?? Icons.event_rounded;
    final dateStr =
        '${dday.targetDate.year.toString().substring(2)}.${dday.targetDate.month.toString().padLeft(2, '0')}.${dday.targetDate.day.toString().padLeft(2, '0')}';

    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.subtleBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dday.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.0,
                  fontWeight: FontWeight.w500,
                  color: c.textTertiary,
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

class _ViewAllChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.ddaySettings),
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: c.subtleBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.borderBlue),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz_rounded, size: 16, color: c.textMuted),
            const SizedBox(height: 3),
            Text(
              '전체',
              style: TextStyle(
                fontSize: 9,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color: c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.ddaySettings),
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: c.subtleBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.borderBlue),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded,
                size: 16, color: Color(0xFF229BF3)),
            const SizedBox(height: 3),
            Text(
              '추가',
              style: TextStyle(
                fontSize: 9,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color: c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
