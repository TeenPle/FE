import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../models/penalty_summary_model.dart';
import '../provider/admin_penalty_provider.dart';
import '../widgets/admin_responsive.dart';

class AdminPenaltyListPage extends ConsumerStatefulWidget {
  const AdminPenaltyListPage({super.key});

  @override
  ConsumerState<AdminPenaltyListPage> createState() =>
      _AdminPenaltyListPageState();
}

class _AdminPenaltyListPageState extends ConsumerState<AdminPenaltyListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminPenaltyListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPenaltyListProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '제재 내역',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: state.isLoading && state.penalties.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.penalties.isEmpty
          ? Center(
              child: Text(
                state.error!,
                style: AppTextStyles.bodyMedium.copyWith(color: c.textMuted),
              ),
            )
          : state.penalties.isEmpty
          ? Center(child: _PenaltyEmptyState(c: c))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(adminPenaltyListProvider.notifier).load(),
              child: AdminContentFrame(
                child: ListView.separated(
                  padding: AdminLayout.pagePadding(context),
                  itemCount: state.penalties.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    if (index == state.penalties.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: state.isLoading
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : OutlinedButton(
                                  onPressed: () => ref
                                      .read(adminPenaltyListProvider.notifier)
                                      .loadMore(),
                                  child: Text('더보기'),
                                ),
                        ),
                      );
                    }
                    return _PenaltyCard(penalty: state.penalties[index]);
                  },
                ),
              ),
            ),
    );
  }
}

class _PenaltyCard extends ConsumerWidget {
  final PenaltySummaryModel penalty;

  const _PenaltyCard({required this.penalty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isCancelled = penalty.status == 'CANCELLED';
    final isActive = penalty.isActive;
    final (statusLabel, statusColor, statusBg) = isCancelled
        ? ('취소됨', c.textTertiary, c.subtleBg)
        : isActive
        ? ('제재 중', const Color(0xFFE05C7B), const Color(0xFFFFF3F3))
        : ('만료', c.textTertiary, c.subtleBg);

    return Material(
      color: Colors.transparent,
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
                color: statusBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isCancelled
                    ? Icons.remove_circle_outline_rounded
                    : isActive
                    ? Icons.gavel_rounded
                    : Icons.check_circle_outline_rounded,
                size: 20,
                color: statusColor,
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
                        child: _PenaltyUserLink(penalty: penalty, c: c),
                      ),
                      const SizedBox(width: 8),
                      _PenaltyStatusPill(
                        label: statusLabel,
                        color: statusColor,
                        backgroundColor: statusBg,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _PenaltyReasonPill(label: penalty.reasonLabel),
                      _PenaltyMeta(
                        icon: Icons.receipt_long_outlined,
                        text: '신고 #${penalty.reportId}',
                        c: c,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _PenaltyMeta(
                    icon: Icons.access_time_rounded,
                    text:
                        '${_formatDate(penalty.createdAt)} ~ ${_formatDate(penalty.expiresAt)}',
                    c: c,
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _onCancel(context, ref),
                        icon: const Icon(Icons.lock_open_rounded, size: 15),
                        label: Text(
                          '제재 취소',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE05C7B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('제재 취소'),
        content: Text('${penalty.userNickname}의 제재를 즉시 해제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '해제',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Color(0xFFE05C7B),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await ref
        .read(adminPenaltyListProvider.notifier)
        .cancel(penalty.penaltyId);
    showAppSnackBar(
      success ? '제재를 취소했어요.' : '제재 취소에 실패했어요.',
      backgroundColor: success ? null : const Color(0xFFE05C7B),
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}';
}

class _PenaltyEmptyState extends StatelessWidget {
  final AppColors c;

  const _PenaltyEmptyState({required this.c});

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
            child: const Icon(Icons.gavel_rounded, color: Color(0xFF1477F8)),
          ),
          const SizedBox(height: 12),
          Text(
            '제재 내역이 없어요.',
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

class _PenaltyStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _PenaltyStatusPill({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
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

class _PenaltyReasonPill extends StatelessWidget {
  final String label;

  const _PenaltyReasonPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.tintBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1477F8),
          height: 1,
        ),
      ),
    );
  }
}

class _PenaltyUserLink extends StatelessWidget {
  final PenaltySummaryModel penalty;
  final AppColors c;

  const _PenaltyUserLink({required this.penalty, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.adminUserHistory(penalty.userId),
        extra: {'nickname': penalty.userNickname},
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 14, color: c.iconSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              penalty.userNickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1477F8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PenaltyMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final AppColors c;

  const _PenaltyMeta({required this.icon, required this.text, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c.iconSecondary),
        const SizedBox(width: 5),
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
    );
  }
}
