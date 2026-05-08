import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
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
    Future.microtask(() => ref.read(adminDashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('관리자 콘솔', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_rounded),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBD3DF)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF426C82)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '익명성은 유지하되, 신고 처리와 안전 대응을 위해 필요한 콘텐츠만 운영 관점에서 확인합니다.',
                    style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF29485A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 720 ? 3 : 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              _ConsoleTile(
                icon: Icons.verified_user_outlined,
                title: '인증 요청',
                subtitle: '학생증 인증 승인/거절',
                badgeCount: dashboard.pendingVerificationCount,
                color: const Color(0xFF426C82),
                background: const Color(0xFFEAF3FB),
                onTap: () => context.push(AppRoutes.adminVerificationList),
              ),
              _ConsoleTile(
                icon: Icons.flag_outlined,
                title: '신고 큐',
                subtitle: '신고 콘텐츠 처리',
                badgeCount: dashboard.pendingReportCount,
                color: const Color(0xFFE05C7B),
                background: const Color(0xFFFFF3F3),
                onTap: () => context.push(AppRoutes.adminReportList),
              ),
              _ConsoleTile(
                icon: Icons.gavel_rounded,
                title: '제재 내역',
                subtitle: '활성/과거 제재 확인',
                color: const Color(0xFF6B5A8E),
                background: const Color(0xFFF1EEFA),
                onTap: () => context.push(AppRoutes.adminPenaltyList),
              ),
              _ConsoleTile(
                icon: Icons.manage_search_rounded,
                title: '학교 모니터링',
                subtitle: '모든 학교 게시판 열람',
                color: const Color(0xFF7C6A46),
                background: const Color(0xFFFFF7E8),
                onTap: () => context.push(AppRoutes.adminSchools),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionTitle('운영 원칙'),
          const SizedBox(height: 10),
          const _GuidelineTile(
            icon: Icons.visibility_outlined,
            title: '열람 목적 제한',
            body: '전체 게시판은 신고 대응, 안전 점검, 운영 확인 목적으로만 확인합니다.',
          ),
          const SizedBox(height: 8),
          const _GuidelineTile(
            icon: Icons.person_off_outlined,
            title: '작성자 정보 최소화',
            body: '익명 게시글은 운영용 식별자로 표시하고, 실명/연락처는 기본 화면에 노출하지 않습니다.',
          ),
          const SizedBox(height: 8),
          const _GuidelineTile(
            icon: Icons.rule_rounded,
            title: '조치 흐름',
            body: '신고 상세에서 콘텐츠 확인, 작성자 이력 확인, 경고 또는 제재 순서로 처리합니다.',
          ),
        ],
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
            child: const Text('취소', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('로그아웃', style: TextStyle(color: Color(0xFFE05C7B))),
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

class _ConsoleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? badgeCount;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ConsoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeCount,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const Spacer(),
                  if (badgeCount != null)
                    _PendingBadge(
                      count: badgeCount!,
                      color: color,
                      background: background,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2933)),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  final int count;
  final Color color;
  final Color background;

  const _PendingBadge({
    required this.count,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 30, minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0 ? color : background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: count > 0 ? Colors.white : color,
        ),
      ),
    );
  }
}

class _GuidelineTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _GuidelineTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1F2933)),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
