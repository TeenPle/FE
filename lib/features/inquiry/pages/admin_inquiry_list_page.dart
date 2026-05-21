import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_format.dart';
import '../../admin/widgets/admin_responsive.dart';
import '../models/inquiry_model.dart';
import '../provider/admin_inquiry_provider.dart';

class AdminInquiryListPage extends ConsumerStatefulWidget {
  const AdminInquiryListPage({super.key});

  @override
  ConsumerState<AdminInquiryListPage> createState() =>
      _AdminInquiryListPageState();
}

class _AdminInquiryListPageState extends ConsumerState<AdminInquiryListPage> {
  static const _tabs = [('PENDING', '답변 대기'), ('ANSWERED', '답변 완료')];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminInquiryListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminInquiryListProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '문의 관리',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: AdminContentFrame(
        child: Column(
          children: [
            Padding(
              padding: AdminLayout.pagePadding(context, top: 12, bottom: 4),
              child: _InquiryTabs(
                tabs: _tabs,
                activeStatus: state.activeStatus,
                onChanged: (status) => ref
                    .read(adminInquiryListProvider.notifier)
                    .load(status: status),
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
                  : state.inquiries.isEmpty
                  ? Center(child: _InquiryEmptyState(c: c))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminInquiryListProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: AdminLayout.pagePadding(context),
                        itemCount: state.inquiries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 7),
                        itemBuilder: (context, index) {
                          final inquiry = state.inquiries[index];
                          return _AdminInquiryTile(
                            inquiry: inquiry,
                            onTap: () async {
                              final changed = await context.push<bool>(
                                AppRoutes.adminInquiryDetail(inquiry.inquiryId),
                              );
                              if (changed == true && context.mounted) {
                                ref
                                    .read(adminInquiryListProvider.notifier)
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
    );
  }
}

class _AdminInquiryTile extends StatelessWidget {
  final InquirySummaryModel inquiry;
  final VoidCallback onTap;

  const _AdminInquiryTile({required this.inquiry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
                  color: inquiry.isAnswered
                      ? c.tintBg
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  inquiry.isAnswered
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  size: 20,
                  color: inquiry.isAnswered
                      ? const Color(0xFF1477F8)
                      : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            inquiry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(answered: inquiry.isAnswered),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InquiryMeta(
                      icon: Icons.person_outline,
                      text: _userLine(inquiry),
                    ),
                    const SizedBox(height: 6),
                    _InquiryMeta(
                      icon: Icons.schedule_rounded,
                      text: timeAgo(inquiry.createdAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: c.iconSecondary,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _userLine(InquirySummaryModel inquiry) {
    final name = inquiry.userName?.trim();
    final nickname = inquiry.userNickname?.trim();
    final school = inquiry.schoolName?.trim();
    final identity = [
      if (name != null && name.isNotEmpty) name,
      if (nickname != null && nickname.isNotEmpty) nickname,
    ].join(' · ');
    if (school == null || school.isEmpty) {
      return identity.isEmpty ? '알 수 없음' : identity;
    }
    if (identity.isEmpty) return school;
    return '$identity · $school';
  }
}

class _InquiryTabs extends StatelessWidget {
  final List<(String, String)> tabs;
  final String activeStatus;
  final ValueChanged<String> onChanged;

  const _InquiryTabs({
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
          final active = tab.$1 == activeStatus;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF1477F8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab.$2,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: active ? Colors.white : c.textSecondary,
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

class _InquiryEmptyState extends StatelessWidget {
  final AppColors c;

  const _InquiryEmptyState({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderBlue),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.tintBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFF1477F8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '문의 내역이 없어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InquiryMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InquiryMeta({required this.icon, required this.text});

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
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool answered;

  const _StatusBadge({required this.answered});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: answered ? c.tintBg : c.subtleBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: answered ? c.borderBlue : c.border),
      ),
      child: Text(
        answered ? '답변 완료' : '답변 대기',
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: answered ? const Color(0xFF14A3F7) : c.textMuted,
        ),
      ),
    );
  }
}
