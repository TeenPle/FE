import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/penalty_summary_model.dart';
import '../provider/admin_penalty_provider.dart';

class AdminPenaltyListPage extends ConsumerStatefulWidget {
  const AdminPenaltyListPage({super.key});

  @override
  ConsumerState<AdminPenaltyListPage> createState() =>
      _AdminPenaltyListPageState();
}

class _AdminPenaltyListPageState
    extends ConsumerState<AdminPenaltyListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminPenaltyListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPenaltyListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text('제재 내역',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: state.isLoading && state.penalties.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.penalties.isEmpty
              ? Center(
                  child: Text(state.error!,
                      style: const TextStyle(color: Colors.grey)))
              : state.penalties.isEmpty
                  ? const Center(
                      child: Text('제재 내역이 없어요.',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminPenaltyListProvider.notifier).load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.penalties.length +
                            (state.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == state.penalties.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              child: Center(
                                child: state.isLoading
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 2)
                                    : OutlinedButton(
                                        onPressed: () => ref
                                            .read(adminPenaltyListProvider
                                                .notifier)
                                            .loadMore(),
                                        child: const Text('더보기'),
                                      ),
                              ),
                            );
                          }
                          return _PenaltyCard(
                              penalty: state.penalties[index]);
                        },
                      ),
                    ),
    );
  }
}

class _PenaltyCard extends StatelessWidget {
  final PenaltySummaryModel penalty;

  const _PenaltyCard({required this.penalty});

  @override
  Widget build(BuildContext context) {
    final expired = penalty.isExpired;

    return Container(
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: expired
                      ? const Color(0xFFF0F0F0)
                      : const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  expired ? '만료' : '제재 중',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: expired
                        ? const Color(0xFF9AA7B2)
                        : const Color(0xFFE05C7B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  penalty.reasonLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A8EA8),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(penalty.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9AA7B2)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: Color(0xFF9AA7B2)),
              const SizedBox(width: 4),
              Text(
                penalty.userNickname,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7C8A)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_rounded,
                  size: 14, color: Color(0xFF9AA7B2)),
              const SizedBox(width: 4),
              Text(
                '${_formatDate(penalty.createdAt)} ~ ${_formatDate(penalty.expiresAt)}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7C8A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '신고 #${penalty.reportId}',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF9AA7B2)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}';
  }
}
