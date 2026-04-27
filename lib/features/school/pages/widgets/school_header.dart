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
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 14),
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
            _HeaderIconButton(
              icon: Icons.person_outline_rounded,
              onTap: () => context.push(AppRoutes.profile),
            ),
            _NotificationIconButton(unreadCount: unreadCount, onTap: () async {
              await context.push(AppRoutes.notifications);
              if (context.mounted) {
                ref.read(notificationProvider.notifier).loadUnreadCount();
              }
            }),
            _HeaderIconButton(
              icon: Icons.settings_outlined,
              onTap: () => context.push(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상단바 공통 아이콘 버튼
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 26, color: Colors.black87),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(),
    );
  }
}

/// 알림 아이콘 버튼 (뱃지 포함)
class _NotificationIconButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationIconButton({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 26, color: Colors.black87),
          if (unreadCount > 0)
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
                    unreadCount > 99 ? '99+' : '$unreadCount',
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
      ),
    );
  }
}
