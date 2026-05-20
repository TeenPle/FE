import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/provider/login_provider.dart';
import '../provider/admin_dashboard_provider.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_reloadDashboard);
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AdminHeader(
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
                            onTap: () =>
                                context.push(AppRoutes.adminPenaltyList),
                          ),
                          _QuickActionTile(
                            icon: Icons.account_balance_rounded,
                            title: '학교 모니터링',
                            subtitle: '학교별 게시판과 게시글 확인',
                            color: const Color(0xFF1477F8),
                            onTap: () => context.push(AppRoutes.adminSchools),
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
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _AdminHeader({required this.onRefresh, required this.onLogout});

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
