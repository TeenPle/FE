import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: const Text(
          '내 경고 이력',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
              ? Center(
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Color(0xFF9AA7B2)),
                  ),
                )
              : state.items.isEmpty
                  ? const Center(
                      child: Text(
                        '경고 이력이 없어요.',
                        style: TextStyle(fontSize: 15, color: Color(0xFF9AA7B2)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(warningHistoryProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        itemCount:
                            state.items.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.items.length) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: state.isLoading
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 2)
                                    : OutlinedButton(
                                        onPressed: () => ref
                                            .read(warningHistoryProvider
                                                .notifier)
                                            .loadMore(),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          side: const BorderSide(
                                              color: Color(0xFFD6DEE7)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text('더보기'),
                                      ),
                              ),
                            );
                          }
                          return _WarningHistoryCard(
                              warning: state.items[index]);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              const Text(
                '관리자 경고',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const Spacer(),
              Text(
                issuedStr,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9AA7B2)),
              ),
            ],
          ),
          if (warning.targetType != null && warning.targetSummary != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '신고된 ${warning.targetTypeLabel}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9AA7B2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning.targetSummary!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF444444),
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
              style: const TextStyle(
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
