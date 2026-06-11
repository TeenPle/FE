import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/provider/login_provider.dart';
import '../../notification/provider/notification_provider.dart';
import '../../notification/service/fcm_service.dart';
import '../provider/admin_dashboard_provider.dart';
import '../widgets/admin_responsive.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_reloadDashboard);
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _reloadDashboard();
    });

    // 관리자도 신고/문의/인증 요청 푸시를 받아야 하므로 학생 홈(school_page)과
    // 동일하게 FCM을 초기화하고 토큰을 등록한다. 관리자는 이 화면이 홈이라
    // school_page를 거치지 않는다 — 여기서 하지 않으면 토큰 등록이 영영 안 된다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fcm = ref.read(fcmServiceProvider);
      fcm.init().catchError((e) {
        if (kDebugMode) debugPrint('[FCM ERROR] $e');
      });
      // 같은 기기에서 일반 유저로 쓰다가 관리자로 전환 로그인한 경우
      // init()은 이미 초기화돼 아무것도 하지 않으므로 현재 계정으로 재등록한다.
      fcm.reRegisterToken();
      fcm.handleInitialMessage();
      ref.read(notificationProvider.notifier).loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _reloadDashboard() {
    return ref.read(adminDashboardProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(adminDashboardProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.cardBg,
      appBar: AppBar(backgroundColor: c.cardBg, toolbarHeight: 0, elevation: 0),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF1477F8),
          onRefresh: _reloadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AdminLayout.pagePadding(context, top: 20, bottom: 28),
            children: [
              AdminContentFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdminHeader(
                      unreadCount: ref.watch(notificationProvider).unreadCount,
                      onNotifications: () =>
                          context.push(AppRoutes.notifications),
                      onRefresh: _reloadDashboard,
                      onLogout: () => _confirmLogout(context, ref),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '관리자 콘솔',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '미처리 요청 현황을 확인하세요',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _TodayStatusCard(dashboard: dashboard),
                    const SizedBox(height: 18),
                    _RecentAdminEventsCard(
                      events: dashboard.recentEvents,
                      onTap: (route) => _pushAndRefresh(route),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle('빠른 작업'),
                    const SizedBox(height: 10),
                    _QuickActionPanel(
                      children: [
                        _QuickActionTile(
                          icon: Icons.verified_user_outlined,
                          title: '인증 요청',
                          subtitle: '학생증 인증 승인/거절',
                          color: const Color(0xFF1477F8),
                          badgeCount: dashboard.pendingVerificationCount,
                          onTap: () =>
                              context.push(AppRoutes.adminVerificationList),
                        ),
                        _QuickActionTile(
                          icon: Icons.flag_outlined,
                          title: '신고 관리',
                          subtitle: '신고 콘텐츠 검토 및 처리',
                          color: const Color(0xFF1477F8),
                          badgeCount: dashboard.pendingReportCount,
                          onTap: () =>
                              _pushAndRefresh(AppRoutes.adminReportList),
                        ),
                        _QuickActionTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: '문의 관리',
                          subtitle: '사용자 문의 답변',
                          color: const Color(0xFF1477F8),
                          badgeCount: dashboard.pendingInquiryCount,
                          onTap: () =>
                              _pushAndRefresh(AppRoutes.adminInquiries),
                        ),
                        _QuickActionTile(
                          icon: Icons.gavel_rounded,
                          title: '제재 이력',
                          subtitle: '활성/과거 제재 확인',
                          color: const Color(0xFF1477F8),
                          onTap: () => context.push(AppRoutes.adminPenaltyList),
                        ),
                        _QuickActionTile(
                          icon: Icons.account_balance_rounded,
                          title: '학교 모니터링',
                          subtitle: '학교별 게시판과 게시글 확인',
                          color: const Color(0xFF1477F8),
                          onTap: () => context.push(AppRoutes.adminSchools),
                        ),
                        _QuickActionTile(
                          icon: Icons.campaign_outlined,
                          title: '광고 관리',
                          subtitle: '앱 광고 배너 등록/수정',
                          color: const Color(0xFF1477F8),
                          onTap: () => context.push(AppRoutes.adminAds),
                        ),
                        _QuickActionTile(
                          icon: Icons.receipt_long_outlined,
                          title: '감사 로그',
                          subtitle: '운영 조치 기록 확인',
                          color: const Color(0xFF1477F8),
                          onTap: () => context.push(AppRoutes.adminAuditLogs),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _FooterNote(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pushAndRefresh(String route) async {
    await context.push(route);
    if (!mounted) return;
    await _reloadDashboard();
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('관리자 계정에서 로그아웃할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '로그아웃',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFE05C7B),
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      await ref.read(loginProvider.notifier).logout();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    });
  }
}

class _AdminHeader extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _AdminHeader({
    required this.unreadCount,
    required this.onNotifications,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1477F8),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1477F8).withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'TeenPle Admin',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium.copyWith(
              color: const Color(0xFF1477F8),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        // 알림함 진입 버튼 — 신고/문의/인증 요청 알림을 푸시를 놓쳐도 확인할 수 있다.
        Stack(
          clipBehavior: Clip.none,
          children: [
            _HeaderButton(
              icon: Icons.notifications_none_rounded,
              tooltip: '알림',
              onTap: onNotifications,
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE05C5C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        _HeaderButton(
          icon: Icons.refresh_rounded,
          tooltip: '새로고침',
          onTap: onRefresh,
        ),
        const SizedBox(width: 10),
        _HeaderButton(
          icon: Icons.logout_rounded,
          tooltip: '로그아웃',
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.subtleBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.borderBlue),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B2447).withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF1477F8)),
          ),
        ),
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  final AdminDashboardState dashboard;

  const _TodayStatusCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final totalPending =
        (dashboard.pendingVerificationCount ?? 0) +
        (dashboard.pendingReportCount ?? 0) +
        (dashboard.pendingInquiryCount ?? 0);
    final metrics = [
      _StatusMetric(
        icon: Icons.verified_user_outlined,
        label: '인증',
        value: dashboard.pendingVerificationCount,
      ),
      _StatusMetric(
        icon: Icons.flag_outlined,
        label: '신고',
        value: dashboard.pendingReportCount,
        muted: true,
      ),
      _StatusMetric(
        icon: Icons.chat_bubble_outline_rounded,
        label: '문의',
        value: dashboard.pendingInquiryCount,
      ),
      _StatusMetric(
        icon: Icons.check_circle_outline_rounded,
        label: '합계',
        value: totalPending,
        muted: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: c.subtleBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderBlue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2447).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF1477F8),
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '미처리 현황',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '실시간',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF1477F8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: _StatusMetricView(metric: metrics[i])),
                if (i != metrics.length - 1)
                  Container(width: 1, height: 46, color: c.dividerBlue),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusMetric {
  final IconData icon;
  final String label;
  final int? value;
  final bool muted;

  const _StatusMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });
}

class _StatusMetricView extends StatelessWidget {
  final _StatusMetric metric;

  const _StatusMetricView({required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = metric.value == null
        ? '-'
        : metric.value! > 99
        ? '99+'
        : '${metric.value}';

    return Column(
      children: [
        Icon(
          metric.icon,
          color: metric.muted ? c.iconOnCard : const Color(0xFF1477F8),
          size: 21,
        ),
        const SizedBox(height: 9),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextStyles.displaySmall.copyWith(
              color: const Color(0xFF1477F8),
              fontWeight: FontWeight.w900,
              fontSize: 15,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            color: c.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _RecentAdminEventsCard extends StatelessWidget {
  final List<AdminDashboardEvent> events;
  final ValueChanged<String> onTap;

  const _RecentAdminEventsCard({required this.events, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.subtleBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderBlue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2447).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFF1477F8),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '최근 대기 항목',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '새로 처리할 항목이 없습니다.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: c.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < events.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: c.borderSubtle),
              _RecentAdminEventTile(event: events[i], onTap: onTap),
            ],
        ],
      ),
    );
  }
}

class _RecentAdminEventTile extends StatelessWidget {
  final AdminDashboardEvent event;
  final ValueChanged<String> onTap;

  const _RecentAdminEventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _eventColor(event.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(event.route),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
          child: Row(
            children: [
              _TintIcon(
                icon: _eventIcon(event.type),
                color: color,
                size: 34,
                iconSize: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.subtitle.isEmpty ? '내용 없음' : event.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.textSecondary,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatRelativeTime(event.createdAt),
                style: AppTextStyles.captionSmall.copyWith(
                  color: c.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: c.iconSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _eventColor(AdminDashboardEventType type) {
    return switch (type) {
      AdminDashboardEventType.verification => const Color(0xFF1477F8),
      AdminDashboardEventType.report => const Color(0xFFE05C7B),
      AdminDashboardEventType.inquiry => const Color(0xFF0E9F6E),
    };
  }

  IconData _eventIcon(AdminDashboardEventType type) {
    return switch (type) {
      AdminDashboardEventType.verification => Icons.verified_user_outlined,
      AdminDashboardEventType.report => Icons.flag_outlined,
      AdminDashboardEventType.inquiry => Icons.chat_bubble_outline_rounded,
    };
  }

  String _formatRelativeTime(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

class _QuickActionPanel extends StatelessWidget {
  final List<Widget> children;

  const _QuickActionPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.subtleBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderStrong),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2447).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 82,
                color: c.borderSubtle,
              ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int? badgeCount;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              _TintIcon(icon: icon, color: color, size: 42, iconSize: 24),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: c.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.textSecondary,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount != null && badgeCount! > 0) ...[
                const SizedBox(width: 10),
                _PendingBadge(count: badgeCount!),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: c.iconSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: context.colors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
    );
  }
}

class _TintIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;

  const _TintIcon({
    required this.icon,
    required this.color,
    required this.size,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.52),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  final int count;

  const _PendingBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 30, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1477F8),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 11,
          height: 1.1,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.subtleBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.borderBlue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF1477F8),
              size: 15,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '안전한 TeenPle 운영에 감사드립니다.',
                textAlign: TextAlign.center,
                style: AppTextStyles.captionSmall.copyWith(
                  color: c.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
