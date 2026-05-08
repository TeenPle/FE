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
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'D-DAY',
                style: TextStyle(
                  fontSize: 20,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF229BF3),
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push(AppRoutes.ddaySettings),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '전체 보기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B0B0B),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: Color(0xFF0B0B0B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sorted.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 9),
              itemBuilder: (ctx, i) {
                if (i == sorted.length) {
                  return _AddChip(
                    onTap: () => context.push(AppRoutes.ddaySettings),
                  );
                }
                return _DDayChip(dday: sorted[i], icon: _iconForIndex(i));
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForIndex(int index) {
    const icons = [
      Icons.school_rounded,
      Icons.directions_run_rounded,
      Icons.edit_rounded,
      Icons.menu_book_rounded,
      Icons.event_rounded,
    ];
    return icons[index % icons.length];
  }
}

class _DDayChip extends StatelessWidget {
  final DDayModel dday;
  final IconData icon;

  const _DDayChip({required this.dday, required this.icon});

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
      width: 116,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6EAFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dday.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F252B),
                  ),
                ),
              ),
              Icon(icon, size: 18, color: accent),
            ],
          ),
          const Spacer(),
          Text(
            dday.dDayLabel,
            style: TextStyle(
              fontSize: 17,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${dday.targetDate.year}.${dday.targetDate.month.toString().padLeft(2, '0')}.${dday.targetDate.day.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D6672),
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
        width: 68,
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FCFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFCBE7FF),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 24, color: Color(0xFF229BF3)),
            SizedBox(height: 4),
            Text(
              '추가',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF229BF3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
