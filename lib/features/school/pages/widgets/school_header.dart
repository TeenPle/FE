import 'package:flutter/material.dart';
import 'package:teenple_frontend/core/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
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
    final c = context.colors;
    final unreadCount = ref.watch(
      notificationProvider.select((s) => s.unreadCount),
    );

    return Container(
      color: c.pageBg,
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 12),
      child: Row(
        children: [
          Image.asset(
            'assets/images/Logo_transparent.png',
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: c.textPrimary,
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
            child: Icon(Icons.search_rounded, size: 29, color: c.iconPrimary),
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
              iconColor: c.iconPrimary,
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
  final Color iconColor;

  const _BadgeIcon({
    required this.icon,
    required this.count,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 29, color: iconColor),
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
                  style: AppTextStyles.bodyMedium.copyWith(
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
