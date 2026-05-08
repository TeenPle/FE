import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../notification/provider/notification_provider.dart';

class SchoolHeader extends ConsumerWidget {
  final String schoolName;
  final VoidCallback onSearchTap;

  const SchoolHeader({
    super.key,
    required this.schoolName,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      notificationProvider.select((s) => s.unreadCount),
    );

    return Container(
      color: const Color(0xFFF6FBFF),
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 12),
      child: Row(
        children: [
          Image.asset(
            'assets/images/Logo.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    schoolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF050505),
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: Color(0xFF229BF3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSearchTap,
            child: const _HeaderIcon(icon: Icons.search_rounded),
          ),
          const SizedBox(width: 13),
          GestureDetector(
            onTap: () async {
              await context.push(AppRoutes.notifications);
              if (context.mounted) {
                ref.read(notificationProvider.notifier).loadUnreadCount();
              }
            },
            child: _BadgeIcon(
              icon: Icons.notifications_none_rounded,
              count: unreadCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 29, color: Color(0xFF0B0B0B)),
        if (count > 0)
          Positioned(
            top: 1,
            right: 1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4E5D),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;

  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 29, color: const Color(0xFF0B0B0B));
  }
}
