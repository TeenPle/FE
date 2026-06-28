import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/warning_model.dart';
import '../provider/warning_provider.dart';

class MyWarningHistoryPage extends ConsumerStatefulWidget {
  const MyWarningHistoryPage({super.key});

  @override
  ConsumerState<MyWarningHistoryPage> createState() =>
      _MyWarningHistoryPageState();
}

class _MyWarningHistoryPageState extends ConsumerState<MyWarningHistoryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(warningHistoryProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warningHistoryProvider);

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        title: Text(
          '내 경고 이력',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
          ? Center(
              child: Text(
                state.error!,
                style: AppTextStyles.bodyMedium.copyWith(color: c.textMuted),
              ),
            )
          : state.items.isEmpty
          ? Center(
              child: Text(
                '경고 이력이 없어요.',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color: c.textMuted,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(warningHistoryProvider.notifier).load(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                itemCount: state.items.length + (state.hasMore ? 1 : 0),
                itemBuilder: (ctx, index) {
                  if (index == state.items.length) {
                    final cc = ctx.colors;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: state.isLoading
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : OutlinedButton(
                                onPressed: () => ref
                                    .read(warningHistoryProvider.notifier)
                                    .loadMore(),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: cc.cardBg,
                                  side: BorderSide(color: cc.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  '더보기',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: cc.textMuted,
                                  ),
                                ),
                              ),
                      ),
                    );
                  }
                  return _WarningHistoryCard(warning: state.items[index]);
                },
              ),
            ),
    );
  }
}

class _WarningHistoryCard extends StatelessWidget {
  final WarningHistoryModel warning;

  const _WarningHistoryCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    final issuedStr =
        '${warning.issuedAt.year}.${warning.issuedAt.month.toString().padLeft(2, '0')}.${warning.issuedAt.day.toString().padLeft(2, '0')}';

    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 6),
              Text(
                '관리자 경고',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const Spacer(),
              Text(
                issuedStr,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
          if (warning.targetType != null && warning.targetSummary != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.subtleBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '신고된 ${warning.targetTypeLabel}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning.targetSummary!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      color: c.textBody,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Text(
              warning.adminComment,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: Color(0xFF78350F),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
