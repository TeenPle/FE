import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
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
    Future.microtask(() {
      if (!mounted) return;
      ref.read(adminDashboardProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(adminDashboardProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(backgroundColor: c.pageBg, toolbarHeight: 0, elevation: 0),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _AdminSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AdminHero(
                        onRefresh: () =>
                            ref.read(adminDashboardProvider.notifier).load(),
                        onLogout: () => _confirmLogout(context, ref),
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle('처리 대기 현황'),
                      const SizedBox(height: 14),
                      _PendingSummaryGrid(
                        items: [
                          _PendingSummaryItem(
                            icon: Icons.verified_user_outlined,
                            label: '인증',
                            count: dashboard.pendingVerificationCount,
                            iconColor: const Color(0xFF1477F8),
                            tintColor: const Color(0xFFEAF3FF),
                            onTap: () =>
                                context.push(AppRoutes.adminVerificationList),
                          ),
                          _PendingSummaryItem(
                            icon: Icons.flag_outlined,
                            label: '신고',
                            count: dashboard.pendingReportCount,
                            iconColor: const Color(0xFF16A979),
                            tintColor: const Color(0xFFE8F8F0),
                            onTap: () async {
                              await context.push(AppRoutes.adminReportList);
                              if (context.mounted) {
                                ref
                                    .read(adminDashboardProvider.notifier)
                                    .load();
                              }
                            },
                          ),
                          _PendingSummaryItem(
                            icon: Icons.support_agent_rounded,
                            label: '문의',
                            count: dashboard.pendingInquiryCount,
                            iconColor: const Color(0xFF7D41B8),
                            tintColor: const Color(0xFFF2EAFB),
                            onTap: () async {
                              await context.push(AppRoutes.adminInquiries);
                              if (context.mounted) {
                                ref
                                    .read(adminDashboardProvider.notifier)
                                    .load();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('관리 메뉴'),
                      const SizedBox(height: 14),
                      _AdminMenuPanel(
                        children: [
                          _AdminMenuTile(
                            icon: Icons.verified_user_outlined,
                            title: '인증 요청',
                            subtitle: '학생증 인증 승인/거절',
                            iconColor: const Color(0xFF1477F8),
                            tintColor: const Color(0xFFEAF3FF),
                            badgeCount: dashboard.pendingVerificationCount,
                            onTap: () =>
                                context.push(AppRoutes.adminVerificationList),
                          ),
                          const _MenuDivider(),
                          _AdminMenuTile(
                            icon: Icons.flag_outlined,
                            title: '신고 관리',
                            subtitle: '신고 콘텐츠 검토 및 처리',
                            iconColor: const Color(0xFF16A979),
                            tintColor: const Color(0xFFE8F8F0),
                            badgeCount: dashboard.pendingReportCount,
                            onTap: () async {
                              await context.push(AppRoutes.adminReportList);
                              if (context.mounted) {
                                ref
                                    .read(adminDashboardProvider.notifier)
                                    .load();
                              }
                            },
                          ),
                          const _MenuDivider(),
                          _AdminMenuTile(
                            icon: Icons.support_agent_rounded,
                            title: '문의 관리',
                            subtitle: '사용자 문의 답변',
                            iconColor: const Color(0xFF7D41B8),
                            tintColor: const Color(0xFFF2EAFB),
                            badgeCount: dashboard.pendingInquiryCount,
                            onTap: () async {
                              await context.push(AppRoutes.adminInquiries);
                              if (context.mounted) {
                                ref
                                    .read(adminDashboardProvider.notifier)
                                    .load();
                              }
                            },
                          ),
                          const _MenuDivider(),
                          _AdminMenuTile(
                            icon: Icons.gavel_rounded,
                            title: '제재 이력',
                            subtitle: '활성/과거 제재 확인',
                            iconColor: const Color(0xFFF08A24),
                            tintColor: const Color(0xFFFFF0E1),
                            onTap: () =>
                                context.push(AppRoutes.adminPenaltyList),
                          ),
                          const _MenuDivider(),
                          _AdminMenuTile(
                            icon: Icons.account_balance_rounded,
                            title: '학교 모니터링',
                            subtitle: '학교별 게시판과 게시글 확인',
                            iconColor: const Color(0xFF317CEB),
                            tintColor: const Color(0xFFEAF3FF),
                            onTap: () => context.push(AppRoutes.adminSchools),
                          ),
                          const _MenuDivider(),
                          _AdminMenuTile(
                            icon: Icons.receipt_long_outlined,
                            title: '감사 로그',
                            subtitle: '운영 조치 기록 확인',
                            iconColor: const Color(0xFF0C9C9A),
                            tintColor: const Color(0xFFE5F7F6),
                            onTap: () => context.push(AppRoutes.adminAuditLogs),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              style: TextStyle(color: context.colors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Color(0xFFE05C7B)),
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

class _AdminSurface extends StatelessWidget {
  final Widget child;

  const _AdminSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2447).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AdminHero extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _AdminHero({required this.onRefresh, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E72FF), Color(0xFF0A46C2)],
          ),
        ),
        child: Stack(
          children: [
            // 오른쪽 배경 장식: 크고 부드러운 반투명 원
            Positioned(
              right: -32,
              top: -32,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 48,
              bottom: -18,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 브랜드 행: 로고 + 서비스명 + 액션 버튼
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'TeenPle Admin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xCCFFFFFF),
                            height: 1.2,
                          ),
                        ),
                      ),
                      _HeaderIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: '새로고침',
                        onTap: onRefresh,
                      ),
                      const SizedBox(width: 8),
                      _HeaderIconButton(
                        icon: Icons.logout_rounded,
                        tooltip: '로그아웃',
                        onTap: onLogout,
                        danger: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 메인 타이틀
                  const Text(
                    '관리자 콘솔',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '오늘의 처리 현황을 확인하세요',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xAAFFFFFF),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    // 파란 그라디언트 헤더 위에 배치되므로 반투명 흰색 배경 사용
    final bgColor = danger
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.20);
    final iconColor = danger ? const Color(0xFFFFB3C6) : Colors.white;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _PendingSummaryGrid extends StatelessWidget {
  final List<_PendingSummaryItem> items;

  const _PendingSummaryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 300;
        if (stacked) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _PendingSummaryCard(item: items[i], compact: false),
                if (i != items.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(
                child: _PendingSummaryCard(
                  item: items[i],
                  compact: constraints.maxWidth < 520,
                ),
              ),
              if (i != items.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _PendingSummaryItem {
  final IconData icon;
  final String label;
  final int? count;
  final Color iconColor;
  final Color tintColor;
  final VoidCallback onTap;

  const _PendingSummaryItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.iconColor,
    required this.tintColor,
    required this.onTap,
  });
}

class _PendingSummaryCard extends StatelessWidget {
  final _PendingSummaryItem item;
  final bool compact;

  const _PendingSummaryCard({required this.item, required this.compact});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = item.count;
    final label = count == null ? '-' : count > 99 ? '99+' : '$count';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: c.borderStrong),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B2447).withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: item.tintColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 17, color: item.iconColor),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1477F8),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMenuPanel extends StatelessWidget {
  final List<Widget> children;

  const _AdminMenuPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderStrong),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2447).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color tintColor;
  final int? badgeCount;
  final VoidCallback onTap;

  const _AdminMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.tintColor,
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
        // LayoutBuilder로 할당된 실제 너비를 기준으로 크기 조절
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 300;
            final iconSize = compact ? 40.0 : 46.0;
            final iconInner = compact ? 22.0 : 26.0;
            final hPad = compact ? 14.0 : 16.0;
            final vPad = compact ? 13.0 : 16.0;
            final titleSize = compact ? 14.0 : 16.0;
            final subtitleSize = compact ? 11.0 : 13.0;
            final gap = compact ? 4.0 : 6.0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              child: Row(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: tintColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: iconInner, color: iconColor),
                  ),
                  SizedBox(width: compact ? 12 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleSize,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: c.textPrimary,
                          ),
                        ),
                        SizedBox(height: gap),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badgeCount != null && badgeCount! > 0) ...[
                    SizedBox(width: compact ? 6 : 10),
                    _PendingBadge(count: badgeCount!),
                  ],
                  SizedBox(width: compact ? 6 : 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: compact ? 22 : 26,
                    color: c.iconSecondary,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 좌측 여백을 타일 아이콘 끝선에 맞춤 (compact 기준 동기화)
        final indent = constraints.maxWidth < 300 ? 66.0 : 76.0;
        return Divider(
          height: 1,
          thickness: 1,
          indent: indent,
          color: context.colors.borderSubtle,
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 360 ? 15.0 : 17.0;
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.2,
        fontWeight: FontWeight.w900,
        color: context.colors.textPrimary,
      ),
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
      constraints: const BoxConstraints(minWidth: 34, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1477F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

