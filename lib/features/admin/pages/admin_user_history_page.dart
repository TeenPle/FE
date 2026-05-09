import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/penalty_summary_model.dart';
import '../models/warning_history_model.dart';
import '../provider/admin_penalty_provider.dart';
import '../provider/admin_warning_provider.dart';

class AdminUserHistoryPage extends ConsumerStatefulWidget {
  final int userId;
  final String userNickname;

  const AdminUserHistoryPage({
    super.key,
    required this.userId,
    required this.userNickname,
  });

  @override
  ConsumerState<AdminUserHistoryPage> createState() =>
      _AdminUserHistoryPageState();
}

class _AdminUserHistoryPageState extends ConsumerState<AdminUserHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref
          .read(adminUserPenaltyProvider(widget.userId).notifier)
          .load();
      ref
          .read(adminUserWarningProvider(widget.userId).notifier)
          .load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: Text(
          '${widget.userNickname} 이력',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5A8EA8),
          unselectedLabelColor: const Color(0xFF9AA7B2),
          indicatorColor: const Color(0xFF5A8EA8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '제재 이력'),
            Tab(text: '경고 이력'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PenaltyTab(userId: widget.userId),
          _WarningTab(userId: widget.userId),
        ],
      ),
    );
  }
}

class _PenaltyTab extends ConsumerWidget {
  final int userId;

  const _PenaltyTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUserPenaltyProvider(userId));

    if (state.isLoading && state.penalties.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.penalties.isEmpty) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: Color(0xFF9AA7B2))),
      );
    }
    if (state.penalties.isEmpty) {
      return const Center(
        child: Text('제재 이력이 없어요.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9AA7B2))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: state.penalties.length,
      itemBuilder: (context, index) =>
          _UserPenaltyCard(penalty: state.penalties[index]),
    );
  }
}

class _UserPenaltyCard extends StatelessWidget {
  final PenaltySummaryModel penalty;

  const _UserPenaltyCard({required this.penalty});

  @override
  Widget build(BuildContext context) {
    final isCancelled = penalty.status == 'CANCELLED';
    final isActive = penalty.isActive;

    final (statusLabel, statusColor, statusBg) = isCancelled
        ? ('취소됨', const Color(0xFF9AA7B2), const Color(0xFFF0F0F0))
        : isActive
            ? ('제재 중', const Color(0xFFE05C7B), const Color(0xFFFFF3F3))
            : ('만료', const Color(0xFF9AA7B2), const Color(0xFFF0F0F0));

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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    )),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  penalty.reasonLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A8EA8),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _fmt(penalty.createdAt),
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF9AA7B2)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_fmt(penalty.createdAt)} ~ ${_fmt(penalty.expiresAt)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7C8A)),
          ),
          const SizedBox(height: 2),
          Text(
            '신고 #${penalty.reportId}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9AA7B2)),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

class _WarningTab extends ConsumerWidget {
  final int userId;

  const _WarningTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUserWarningProvider(userId));

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: Color(0xFF9AA7B2))),
      );
    }
    if (state.items.isEmpty) {
      return const Center(
        child: Text('경고 이력이 없어요.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9AA7B2))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: state.items.length,
      itemBuilder: (context, index) =>
          _UserWarningCard(warning: state.items[index]),
    );
  }
}

class _UserWarningCard extends StatelessWidget {
  final AdminWarningHistoryModel warning;

  const _UserWarningCard({required this.warning});

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
                  size: 15, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              const Text(
                '경고',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF59E0B),
                ),
              ),
              if (warning.reportId != null) ...[
                const SizedBox(width: 8),
                Text(
                  '신고 #${warning.reportId}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9AA7B2)),
                ),
              ],
              const Spacer(),
              Text(
                issuedStr,
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF9AA7B2)),
              ),
            ],
          ),
          if (warning.targetType != null && warning.targetSummary != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9AA7B2)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning.targetSummary!,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF444444), height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Text(
              warning.adminComment,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF78350F), height: 1.5),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                warning.isRead
                    ? Icons.check_circle_outline
                    : Icons.circle_outlined,
                size: 13,
                color: warning.isRead
                    ? const Color(0xFF43A047)
                    : const Color(0xFF9AA7B2),
              ),
              const SizedBox(width: 4),
              Text(
                warning.isRead ? '읽음' : '미확인',
                style: TextStyle(
                  fontSize: 11,
                  color: warning.isRead
                      ? const Color(0xFF43A047)
                      : const Color(0xFF9AA7B2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
