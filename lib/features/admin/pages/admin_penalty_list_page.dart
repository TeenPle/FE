import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../models/penalty_summary_model.dart';
import '../provider/admin_penalty_provider.dart';

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
            fontWeight: FontWeight.w700,
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
          ? Center(
              child: Text(
                '제재 내역이 없어요.',
                style: AppTextStyles.bodyMedium.copyWith(color: c.textMuted),
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(adminPenaltyListProvider.notifier).load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.penalties.length + (state.hasMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
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

    return Container(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.tintBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  penalty.reasonLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.iconOnCard,
                  ),
                ),
              ),
              Text(
                _formatDate(penalty.createdAt),
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
              _PenaltyUserLink(penalty: penalty, c: c),
              _PenaltyMeta(
                icon: Icons.access_time_rounded,
                text:
                    '${_formatDate(penalty.createdAt)} ~ ${_formatDate(penalty.expiresAt)}',
                c: c,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '신고 #${penalty.reportId}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 11,
                  color: c.textTertiary,
                ),
              ),
              const Spacer(),
              if (isActive)
                TextButton(
                  onPressed: () => _onCancel(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE05C7B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '제재 취소',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
      success ? '제재가 취소되었습니다.' : '제재 취소에 실패했습니다.',
      backgroundColor: success ? null : const Color(0xFFE05C7B),
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}';
}

class _PenaltyUserLink extends StatelessWidget {
  final PenaltySummaryModel penalty;
  final AppColors c;

  const _PenaltyUserLink({required this.penalty, required this.c});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 14, color: c.iconSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: GestureDetector(
              onTap: () => context.push(
                AppRoutes.adminUserHistory(penalty.userId),
                extra: {'nickname': penalty.userNickname},
              ),
              child: Text(
                penalty.userNickname,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 11,
                  color: const Color(0xFF426C82),
                  decoration: TextDecoration.underline,
                ),
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

  const _PenaltyMeta({
    required this.icon,
    required this.text,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
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
