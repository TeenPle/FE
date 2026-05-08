import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../models/admin_audit_log_model.dart';
import '../provider/admin_audit_log_provider.dart';

class AdminAuditLogPage extends ConsumerStatefulWidget {
  const AdminAuditLogPage({super.key});

  @override
  ConsumerState<AdminAuditLogPage> createState() => _AdminAuditLogPageState();
}

class _AdminAuditLogPageState extends ConsumerState<AdminAuditLogPage> {
  final _scrollController = ScrollController();
  final _adminIdController = TextEditingController();
  String? _action;
  String? _targetType;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminAuditLogProvider.notifier).load());
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 240) {
        ref.read(adminAuditLogProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _adminIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAuditLogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('감사 로그', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _applyFilters,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: (state.isLoading ? 1 : state.logs.length) + 1 + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) return _FilterPanel(state: state, parent: this);
            if (state.isLoading) {
              return const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final logIndex = index - 1;
            if (logIndex >= state.logs.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _AuditLogTile(log: state.logs[logIndex]);
          },
        ),
      ),
    );
  }

  Future<void> _applyFilters() {
    return ref.read(adminAuditLogProvider.notifier).load(
          action: _action,
          targetType: _targetType,
          adminId: int.tryParse(_adminIdController.text.trim()),
          from: _from,
          to: _to,
        );
  }

  Future<void> _clearFilters() {
    setState(() {
      _action = null;
      _targetType = null;
      _from = null;
      _to = null;
      _adminIdController.clear();
    });
    return ref.read(adminAuditLogProvider.notifier).clearFilters();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }
}

class _FilterPanel extends StatelessWidget {
  final AdminAuditLogState state;
  final _AdminAuditLogPageState parent;

  const _FilterPanel({required this.state, required this.parent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: parent._action,
                  decoration: const InputDecoration(labelText: '액션'),
                  items: const [
                    DropdownMenuItem(value: 'VIEW_POST_DETAIL', child: Text('상세 열람')),
                    DropdownMenuItem(value: 'HIDE_POST', child: Text('게시글 숨김')),
                    DropdownMenuItem(value: 'RESTORE_POST', child: Text('게시글 복구')),
                    DropdownMenuItem(value: 'HIDE_COMMENT', child: Text('댓글 숨김')),
                    DropdownMenuItem(value: 'RESTORE_COMMENT', child: Text('댓글 복구')),
                    DropdownMenuItem(value: 'APPROVE_REPORT', child: Text('신고 승인')),
                    DropdownMenuItem(value: 'REJECT_REPORT', child: Text('신고 거절')),
                    DropdownMenuItem(value: 'WARN_REPORT', child: Text('경고')),
                    DropdownMenuItem(value: 'CANCEL_PENALTY', child: Text('제재 취소')),
                  ],
                  onChanged: (value) => parent.setState(() => parent._action = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: parent._targetType,
                  decoration: const InputDecoration(labelText: '대상'),
                  items: const [
                    DropdownMenuItem(value: 'POST', child: Text('게시글')),
                    DropdownMenuItem(value: 'COMMENT', child: Text('댓글')),
                    DropdownMenuItem(value: 'REPORT', child: Text('신고')),
                    DropdownMenuItem(value: 'PENALTY', child: Text('제재')),
                  ],
                  onChanged: (value) => parent.setState(() => parent._targetType = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: parent._adminIdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '관리자 ID', prefixIcon: Icon(Icons.person_search_outlined)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _DateButton(label: '시작일', date: parent._from, onTap: () => parent._pickDate(isFrom: true))),
              const SizedBox(width: 10),
              Expanded(child: _DateButton(label: '종료일', date: parent._to, onTap: () => parent._pickDate(isFrom: false))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: parent._clearFilters,
                  child: const Text('초기화'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: parent._applyFilters,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF426C82), foregroundColor: Colors.white),
                  child: const Text('필터 적용'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(date == null ? label : '${date!.year}.${date!.month}.${date!.day}'),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AdminAuditLogModel log;

  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.action);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(_actionLabel(log.action),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
              ),
              const Spacer(),
              Text(_formatDate(log.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_targetLabel(log.targetType)} #${log.targetId}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F2933)),
                ),
              ),
              if (_canOpenTarget(log))
                TextButton.icon(
                  onPressed: () => _openTarget(context, log),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('이동'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('처리자: ${log.adminNickname} (${log.adminId})',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          if (log.reason != null && log.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.reason!, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.45)),
          ],
          if (log.metadata != null && log.metadata!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.metadata!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ],
      ),
    );
  }

  bool _canOpenTarget(AdminAuditLogModel log) {
    return log.targetType == 'POST' || log.targetType == 'REPORT' || log.targetType == 'PENALTY' || _commentPostId(log) != null;
  }

  void _openTarget(BuildContext context, AdminAuditLogModel log) {
    if (log.targetType == 'POST') {
      context.push(AppRoutes.adminPostDetail(log.targetId));
    } else if (log.targetType == 'REPORT') {
      context.push(AppRoutes.adminReportDetail(log.targetId));
    } else if (log.targetType == 'PENALTY') {
      context.push(AppRoutes.adminPenaltyList);
    } else {
      final postId = _commentPostId(log);
      if (postId != null) {
        context.push(AppRoutes.adminPostDetail(postId), extra: {'focusCommentId': log.targetId});
      }
    }
  }

  int? _commentPostId(AdminAuditLogModel log) {
    final metadata = log.metadata;
    if (log.targetType != 'COMMENT' || metadata == null) return null;
    final match = RegExp(r'postId=(\d+)').firstMatch(metadata);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  Color _actionColor(String action) {
    if (action.contains('HIDE')) return const Color(0xFFE05C7B);
    if (action.contains('RESTORE')) return const Color(0xFF2F7D46);
    if (action.contains('APPROVE') || action.contains('WARN')) return const Color(0xFFF59E0B);
    return const Color(0xFF426C82);
  }

  String _actionLabel(String action) {
    return switch (action) {
      'VIEW_POST_DETAIL' => '상세 열람',
      'HIDE_POST' => '게시글 숨김',
      'RESTORE_POST' => '게시글 복구',
      'HIDE_COMMENT' => '댓글 숨김',
      'RESTORE_COMMENT' => '댓글 복구',
      'APPROVE_REPORT' => '신고 승인',
      'REJECT_REPORT' => '신고 거절',
      'WARN_REPORT' => '경고 처리',
      'CANCEL_PENALTY' => '제재 취소',
      _ => action,
    };
  }

  String _targetLabel(String targetType) {
    return switch (targetType) {
      'POST' => '게시글',
      'COMMENT' => '댓글',
      'REPORT' => '신고',
      'PENALTY' => '제재',
      _ => targetType,
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
