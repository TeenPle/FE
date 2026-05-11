import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../models/report_summary_model.dart';
import '../provider/admin_report_provider.dart';

class AdminReportListPage extends ConsumerStatefulWidget {
  const AdminReportListPage({super.key});

  @override
  ConsumerState<AdminReportListPage> createState() =>
      _AdminReportListPageState();
}

class _AdminReportListPageState extends ConsumerState<AdminReportListPage> {
  static const _tabs = [
    ('PENDING', '대기 중'),
    ('RESOLVED', '처리 완료'),
    ('REJECTED', '거절됨'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminReportListProvider.notifier).load(status: 'PENDING'));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportListProvider);

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.cardBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: const Text('신고 관리',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _StatusTabBar(
            activeStatus: state.activeStatus,
            tabs: _tabs,
            onTap: (status) =>
                ref.read(adminReportListProvider.notifier).load(status: status),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Text(state.error!,
                            style: TextStyle(color: c.textMuted)))
                    : state.reports.isEmpty
                        ? Center(
                            child: Text('신고 내역이 없어요.',
                                style: TextStyle(color: c.textMuted)))
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(adminReportListProvider.notifier)
                                .refresh(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.reports.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) => _ReportCard(
                                report: state.reports[index],
                                onTap: () => context.push(
                                  AppRoutes.adminReportDetail(
                                      state.reports[index].reportId),
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

class _StatusTabBar extends StatelessWidget {
  final String activeStatus;
  final List<(String, String)> tabs;
  final ValueChanged<String> onTap;

  const _StatusTabBar({
    required this.activeStatus,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.cardBg,
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab.$1 == activeStatus;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(tab.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? const Color(0xFF5A8EA8)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color:
                        isActive ? const Color(0xFF5A8EA8) : c.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportSummaryModel report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeBadge(report.targetTypeLabel),
                const SizedBox(width: 8),
                _ReasonBadge(report.reportReasonLabel),
                const Spacer(),
                Text(
                  _formatDate(report.createdAt),
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF9AA7B2)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: Color(0xFF9AA7B2)),
                const SizedBox(width: 4),
                Text('신고자: ${report.reporterNickname}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7C8A))),
                const SizedBox(width: 16),
                const Icon(Icons.gavel_rounded,
                    size: 14, color: Color(0xFF9AA7B2)),
                const SizedBox(width: 4),
                Text('피신고자: ${report.reportedUserNickname}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7C8A))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: Color(0xFFB0BEC5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  const _TypeBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FB),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A8EA8))),
    );
  }
}

class _ReasonBadge extends StatelessWidget {
  final String label;
  const _ReasonBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE05C7B))),
    );
  }
}
