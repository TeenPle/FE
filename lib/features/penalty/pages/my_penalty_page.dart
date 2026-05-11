import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/penalty_model.dart';
import '../provider/penalty_provider.dart';

class MyPenaltyPage extends ConsumerStatefulWidget {
  const MyPenaltyPage({super.key});

  @override
  ConsumerState<MyPenaltyPage> createState() => _MyPenaltyPageState();
}

class _MyPenaltyPageState extends ConsumerState<MyPenaltyPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activePenaltyProvider.notifier).load();
      ref.read(penaltyHistoryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activePenaltyProvider);
    final history = ref.watch(penaltyHistoryProvider);

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        title: Text(
          '제재 이력',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _ActivePenaltyCard(state: active),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              '제재 이력',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.textTertiary,
                letterSpacing: 0.3,
              ),
            ),
          ),

          if (history.isLoading && history.items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (history.error != null && history.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  history.error!,
                  style: TextStyle(color: c.textMuted),
                ),
              ),
            )
          else if (history.items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.borderStrong),
              ),
              child: Text(
                '제재 이력이 없어요.',
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
            )
          else
            Column(
              children: [
                ...history.items.map((p) => _PenaltyHistoryCard(penalty: p)),
                if (history.hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: history.isLoading
                            ? null
                            : () => ref
                                .read(penaltyHistoryProvider.notifier)
                                .loadMore(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: c.cardBg,
                          side: BorderSide(color: c.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: history.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                '더보기',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.textMuted,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivePenaltyCard extends StatelessWidget {
  final ActivePenaltyState state;

  const _ActivePenaltyCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (state.isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.borderStrong),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final penalty = state.penalty;
    final isPenalized = state.isPenalized;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPenalized
            ? const Color(0xFFFFF3F3)
            : const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPenalized
              ? const Color(0xFFFFCDD2)
              : const Color(0xFFC8E6C9),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPenalized
                ? Icons.gavel_rounded
                : Icons.check_circle_outline_rounded,
            color: isPenalized
                ? const Color(0xFFE05C7B)
                : const Color(0xFF43A047),
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isPenalized && penalty != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '현재 제재 중',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE05C7B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '사유: ${penalty.reasonLabel}',
                        style: TextStyle(fontSize: 11, color: c.iconOnCard),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '해제 예정: ${_formatDate(penalty.expiresAt!)}',
                        style: TextStyle(fontSize: 11, color: c.iconOnCard),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '제재 기간 중 게시글·댓글 작성 및 채팅이 제한됩니다.',
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '정상 이용 중',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF43A047),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '현재 활성 제재가 없어요.',
                        style: TextStyle(fontSize: 11, color: c.iconOnCard),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _PenaltyHistoryCard extends StatelessWidget {
  final PenaltyHistoryModel penalty;

  const _PenaltyHistoryCard({required this.penalty});

  @override
  Widget build(BuildContext context) {
    final expired = penalty.isExpired;

    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderStrong),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: expired ? c.subtleBg : const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              expired ? '만료' : '제재 중',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: expired ? c.textMuted : const Color(0xFFE05C7B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  penalty.reasonLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textBody,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(penalty.createdAt)} ~ ${_formatDate(penalty.expiresAt)}',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}
