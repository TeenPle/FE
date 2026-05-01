import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../notification/provider/notification_provider.dart';

class SchoolHeader extends ConsumerWidget {
  final String schoolName;

  const SchoolHeader({
    super.key,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.select((s) => s.unreadCount));

    return Container(
      color: const Color(0xFFF3F9FF),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              color: const Color(0xFF9A9A9A),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                schoolName,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: const _CircleIcon(icon: Icons.account_circle_outlined),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                await context.push(AppRoutes.notifications);
                if (context.mounted) {
                  ref.read(notificationProvider.notifier).loadUnreadCount();
                }
              },
              child: _BadgeIcon(
                icon: Icons.notifications_none,
                count: unreadCount,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => context.push(AppRoutes.settings),
              child: const _CircleIcon(icon: Icons.settings_outlined),
            ),
          ],
        ),
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
        Icon(icon, size: 28, color: Colors.black87),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFE05C7B),
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

class _CircleIcon extends StatelessWidget {
  final IconData icon;

  const _CircleIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 28,
      color: Colors.black87,
    );
  }
}
