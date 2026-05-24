import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/report_summary_model.dart';
import '../provider/admin_report_provider.dart';
import '../widgets/admin_responsive.dart';

class AdminReportListPage extends ConsumerStatefulWidget {
  const AdminReportListPage({super.key});

  @override
  ConsumerState<AdminReportListPage> createState() =>
      _AdminReportListPageState();
}

class _AdminReportListPageState extends ConsumerState<AdminReportListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  static const _tabs = [
    ('PENDING', '대기 중'),
    ('RESOLVED', '처리 완료'),
    ('WARNED', '경고'),
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
    _searchDebounce?.cancel();
    _searchController.dispose();
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

  void _search(String keyword) {
    _searchDebounce?.cancel();
    ref.read(adminReportListProvider.notifier).search(keyword);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _onSearchChanged(String keyword) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _search(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportListProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      body: SafeArea(
        child: AdminContentFrame(
          child: Column(
            children: [
              const AdminPageHeader(
                title: '신고 관리',
                subtitle: '신고 콘텐츠를 검토하고 운영 조치를 처리합니다.',
              ),
              Padding(
                padding: AdminLayout.pagePadding(context, top: 16, bottom: 4),
                child: Column(
                  children: [
                    _AdminSearchField(
                      controller: _searchController,
                      hintText: '신고자, 피신고자, 상세 사유 검색',
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        _search('');
                      },
                    ),
                    const SizedBox(height: 10),
                    _ReportStatusTabs(
                      tabs: _tabs,
                      activeStatus: state.activeStatus,
                      onChanged: (status) => ref
                          .read(adminReportListProvider.notifier)
                          .load(status: status),
                    ),
                  ],
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
                    ? const _ReportEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(adminReportListProvider.notifier)
                            .refresh(),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: AdminLayout.pagePadding(context),
                          itemCount:
                              state.reports.length +
                              (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 7),
                          itemBuilder: (context, index) {
                            if (index >= state.reports.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
        ),
      ),
    );
  }
}

class _AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _AdminSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onChanged,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClear,
        ),
        filled: true,
        fillColor: c.subtleBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.borderBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.borderBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1477F8), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _ReportEmptyState extends StatelessWidget {
  const _ReportEmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 28, color: c.iconSecondary),
            const SizedBox(height: 10),
            Text(
              '신고 내역이 없어요.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.textBody,
              ),
            ),
          ],
        ),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.borderBlue),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B2447).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _statusColor(report.status).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _statusIcon(report.status),
                  size: 20,
                  color: _statusColor(report.status),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.reportReasonLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: c.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _TypeBadge(report.targetTypeLabel),
                        _ReasonBadge(report.reportReasonLabel),
                      ],
                    ),
                    const SizedBox(height: 9),
                    _ReportMeta(
                      icon: Icons.person_outline,
                      text: '신고자 ${report.reporterNickname}',
                    ),
                    const SizedBox(height: 6),
                    _ReportMeta(
                      icon: Icons.gavel_rounded,
                      text: '피신고자 ${report.reportedUserNickname}',
                    ),
                    const SizedBox(height: 6),
                    _ReportMeta(
                      icon: Icons.schedule_rounded,
                      text: _formatDate(report.createdAt),
                    ),
                    if (report.penaltyDays != null) ...[
                      const SizedBox(height: 6),
                      _ReportMeta(
                        icon: Icons.timer_outlined,
                        text: '${report.penaltyDays}일 제재',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 23,
                color: c.iconSecondary,
              ),
            ],
          ),
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

  const _ReportMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 14, color: c.iconSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              color: c.textSecondary,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportStatusTabs extends StatelessWidget {
  final List<(String, String)> tabs;
  final String activeStatus;
  final ValueChanged<String> onChanged;

  const _ReportStatusTabs({
    required this.tabs,
    required this.activeStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderBlue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2447).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab.$1 == activeStatus;
          final color = _statusColor(tab.$1);
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isActive ? Colors.white : c.textSecondary,
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = switch (status) {
      'PENDING' => '대기',
      'RESOLVED' => '완료',
      'REJECTED' => '거절',
      'WARNED' => '경고',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

Color _statusColor(String status) => switch (status) {
  'PENDING' => const Color(0xFF1477F8),
  'RESOLVED' => const Color(0xFF2F7D46),
  'REJECTED' => const Color(0xFFE05C7B),
  'WARNED' => const Color(0xFFF59E0B),
  _ => const Color(0xFF7D8790),
};

IconData _statusIcon(String status) => switch (status) {
  'PENDING' => Icons.flag_outlined,
  'RESOLVED' => Icons.check_circle_outline_rounded,
  'REJECTED' => Icons.cancel_outlined,
  'WARNED' => Icons.warning_amber_rounded,
  _ => Icons.flag_outlined,
};

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
