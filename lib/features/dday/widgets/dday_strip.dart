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

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        itemCount: sorted.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          if (i == sorted.length) {
            return _AddChip(
              onTap: () => context.push(AppRoutes.ddaySettings),
            );
          }
          return _DDayChip(dday: sorted[i]);
        },
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dday.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            dday.dDayLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD0D8E4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15, color: Color(0xFF9AA7B2)),
            SizedBox(width: 4),
            Text(
              'D-Day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9AA7B2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
