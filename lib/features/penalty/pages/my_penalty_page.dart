import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: const Text(
          '제재 이력',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 현재 제재 상태 카드
          _ActivePenaltyCard(state: active),
          const SizedBox(height: 24),

          // 이력 섹션
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              '제재 이력',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA7B2),
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
                  style: const TextStyle(color: Color(0xFF9AA7B2)),
                ),
              ),
            )
          else if (history.items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6EDF3)),
              ),
              child: const Text(
                '제재 이력이 없어요.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9AA7B2)),
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
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD6DEE7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: history.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text(
                                '더보기',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5C6975),
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
    if (state.isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EDF3)),
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7C8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '해제 예정: ${_formatDate(penalty.expiresAt!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7C8A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '제재 기간 중 게시글·댓글 작성 및 채팅이 제한됩니다.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9AA7B2),
                          height: 1.4,
                        ),
                      ),
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '정상 이용 중',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF43A047),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '현재 활성 제재가 없어요.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7C8A),
                        ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: expired
                  ? const Color(0xFFF0F0F0)
                  : const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              expired ? '만료' : '제재 중',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: expired
                    ? const Color(0xFF9AA7B2)
                    : const Color(0xFFE05C7B),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(penalty.createdAt)} ~ ${_formatDate(penalty.expiresAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9AA7B2),
                  ),
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
