import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
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
          style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.borderBlue),
              ),
              child: Row(
                children: _tabs.map((tab) {
                  final active = tab.$1 == state.activeStatus;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(adminInquiryListProvider.notifier)
                          .load(status: tab.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF1477F8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1477F8,
                                    ).withValues(alpha: 0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          tab.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : c.textSecondary,
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
                      style: TextStyle(color: c.textMuted),
                    ),
                  )
                : state.inquiries.isEmpty
                ? Center(
                    child: Text(
                      '문의 내역이 없어요.',
                      style: TextStyle(color: c.textMuted),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(adminInquiryListProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.inquiries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(answered: inquiry.isAnswered),
                  const Spacer(),
                  Text(
                    timeAgo(inquiry.createdAt),
                    style: TextStyle(fontSize: 11, color: c.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                inquiry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: c.iconSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _userLine(inquiry),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: c.iconSecondary,
                    size: 18,
                  ),
                ],
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
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: answered ? const Color(0xFF14A3F7) : c.textMuted,
        ),
      ),
    );
  }
}
