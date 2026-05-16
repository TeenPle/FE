import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
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
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.0),
      ),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.ddaySettings),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 36,
          margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: sorted.isEmpty
                    ? c.textDisabled
                    : const Color(0xFF229BF3),
              ),
              const SizedBox(width: 8),
              if (sorted.isEmpty)
                Expanded(
                  child: Text(
                    '중요한 날짜를 D-Day로 기록해보세요',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: c.textDisabled,
                      letterSpacing: 0,
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (int i = 0; i < sorted.length; i++) ...[
                          _InlineDDayText(
                            label: sorted[i].label,
                            dDayLabel: sorted[i].dDayLabel,
                            color: _accentColor(sorted[i].daysRemaining),
                          ),
                          if (i != sorted.length - 1) _Dot(color: c.textTertiary),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                sorted.isEmpty ? Icons.add_rounded : Icons.chevron_right_rounded,
                size: sorted.isEmpty ? 17 : 18,
                color: c.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentColor(int daysRemaining) {
    if (daysRemaining == 0) return const Color(0xFFE05C7B);
    if (daysRemaining > 0 && daysRemaining <= 7) {
      return const Color(0xFFFF6B35);
    }
    if (daysRemaining > 0) return const Color(0xFF229BF3);
    return const Color(0xFF9AA7B2);
  }
}

class _InlineDDayText extends StatelessWidget {
  final String label;
  final String dDayLabel;
  final Color color;

  const _InlineDDayText({
    required this.label,
    required this.dDayLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 82),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w700,
              color: c.textBody,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          dDayLabel,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
