import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/report_summary_model.dart';
import '../provider/admin_report_provider.dart';

class AdminReportListPage extends ConsumerStatefulWidget {
  const AdminReportListPage({super.key});

  @override
  ConsumerState<AdminReportListPage> createState() =>
      _AdminReportListPageState();
}

class _AdminReportListPageState extends ConsumerState<AdminReportListPage> {
  final _scrollController = ScrollController();

  static const _tabs = [
    ('PENDING', '대기 중'),
    ('RESOLVED', '처리 완료'),
    ('REJECTED', '거절됨'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminReportListProvider.notifier).load(status: 'PENDING'),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      // 목록은 서버에서 20개씩만 가져온다. 하단 근처에 도달했을 때만 다음 페이지를 붙인다.
      ref.read(adminReportListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportListProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(
          '신고 관리',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: _tabs.map((tab) {
                  final isActive = tab.$1 == state.activeStatus;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(adminReportListProvider.notifier)
                          .load(status: tab.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF4A67F2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isActive
                              ? const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          tab.$2,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? Center(
                    child: Text(
                      state.error!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  )
                : state.reports.isEmpty
                ? Center(
                    child: Text(
                      '신고 내역이 없어요.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(adminReportListProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          state.reports.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= state.reports.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        return _ReportCard(
                          report: state.reports[index],
                          onTap: () async {
                            final changed = await context.push<bool>(
                              AppRoutes.adminReportDetail(
                                state.reports[index].reportId,
                              ),
                            );
                            if (changed == true && context.mounted) {
                              ref
                                  .read(adminReportListProvider.notifier)
                                  .refresh();
                            }
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
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
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _TypeBadge(report.targetTypeLabel),
                _ReasonBadge(report.reportReasonLabel),
                Text(
                  _formatDate(report.createdAt),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ReportMeta(
                  icon: Icons.person_outline,
                  text: '신고자: ${report.reporterNickname}',
                  c: c,
                ),
                _ReportMeta(
                  icon: Icons.gavel_rounded,
                  text: '피신고자: ${report.reportedUserNickname}',
                  c: c,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: c.iconSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ReportMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final AppColors c;

  const _ReportMeta({
    required this.icon,
    required this.text,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.iconSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  const _TypeBadge(this.label);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.tintBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.iconOnCard,
        ),
      ),
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
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE05C7B),
        ),
      ),
    );
  }
}
