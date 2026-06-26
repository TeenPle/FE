import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/admin_audit_log_model.dart';
import '../provider/admin_audit_log_provider.dart';
import '../widgets/admin_responsive.dart';

class AdminAuditLogPage extends ConsumerStatefulWidget {
  const AdminAuditLogPage({super.key});

  @override
  ConsumerState<AdminAuditLogPage> createState() => _AdminAuditLogPageState();
}

class _AdminAuditLogPageState extends ConsumerState<AdminAuditLogPage> {
  final _scrollController = ScrollController();
  String? _action;
  String? _targetType;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminAuditLogProvider.notifier).load());
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 240) {
        ref.read(adminAuditLogProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAuditLogProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      body: SafeArea(
        child: AdminContentFrame(
          child: Column(
            children: [
              const AdminPageHeader(
                title: '감사 로그',
                subtitle: '관리자 처리 이력과 열람 기록을 확인합니다.',
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _applyFilters,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: AdminLayout.pagePadding(context, top: 16),
                    itemCount:
                        (state.isLoading
                            ? 1
                            : (state.logs.isEmpty ? 1 : state.logs.length)) +
                        1 +
                        (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _FilterPanel(
                          action: _action,
                          targetType: _targetType,
                          from: _from,
                          to: _to,
                          onActionChanged: (value) =>
                              setState(() => _action = value),
                          onTargetTypeChanged: (value) =>
                              setState(() => _targetType = value),
                          onPickFrom: () => _pickDate(isFrom: true),
                          onPickTo: () => _pickDate(isFrom: false),
                          onClearFilters: _clearFilters,
                          onApplyFilters: _applyFilters,
                        );
                      }
                      if (state.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 120),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (state.logs.isEmpty) {
                        return const _AuditEmptyCard();
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyFilters() {
    return ref
        .read(adminAuditLogProvider.notifier)
        .load(action: _action, targetType: _targetType, from: _from, to: _to);
  }

  Future<void> _clearFilters() {
    setState(() {
      _action = null;
      _targetType = null;
      _from = null;
      _to = null;
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
  final String? action;
  final String? targetType;
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<String?> onActionChanged;
  final ValueChanged<String?> onTargetTypeChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClearFilters;
  final VoidCallback onApplyFilters;

  const _FilterPanel({
    required this.action,
    required this.targetType,
    required this.from,
    required this.to,
    required this.onActionChanged,
    required this.onTargetTypeChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClearFilters,
    required this.onApplyFilters,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1477F8).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  color: Color(0xFF1477F8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '로그 필터',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '액션, 대상, 기간으로 운영 기록을 좁혀봅니다.',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: action,
            decoration: _inputDecoration(context, '액션'),
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
              DropdownMenuItem(
                value: 'VIEW_VERIFICATION_REQUEST',
                child: Text('인증 상세 열람'),
              ),
              DropdownMenuItem(
                value: 'APPROVE_VERIFICATION_REQUEST',
                child: Text('인증 승인'),
              ),
              DropdownMenuItem(
                value: 'REJECT_VERIFICATION_REQUEST',
                child: Text('인증 거절'),
              ),
              DropdownMenuItem(
                value: 'VIEW_INQUIRY_DETAIL',
                child: Text('문의 상세 열람'),
              ),
              DropdownMenuItem(value: 'ANSWER_INQUIRY', child: Text('문의 답변')),
            ],
            onChanged: onActionChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: targetType,
            decoration: _inputDecoration(context, '대상'),
            items: const [
              DropdownMenuItem(value: 'POST', child: Text('게시글')),
              DropdownMenuItem(value: 'COMMENT', child: Text('댓글')),
              DropdownMenuItem(value: 'REPORT', child: Text('신고')),
              DropdownMenuItem(value: 'PENALTY', child: Text('제재')),
              DropdownMenuItem(
                value: 'VERIFICATION_REQUEST',
                child: Text('인증 요청'),
              ),
              DropdownMenuItem(value: 'INQUIRY', child: Text('문의')),
            ],
            onChanged: onTargetTypeChanged,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 330;
              if (stacked) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _DateButton(
                        label: '시작일',
                        date: from,
                        onTap: onPickFrom,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _DateButton(
                        label: '종료일',
                        date: to,
                        onTap: onPickTo,
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: '시작일',
                      date: from,
                      onTap: onPickFrom,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateButton(label: '종료일', date: to, onTap: onPickTo),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 330;
              final clearButton = OutlinedButton(
                onPressed: onClearFilters,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: c.borderBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  foregroundColor: c.textSecondary,
                ),
                child: Text('초기화'),
              );
              final applyButton = ElevatedButton(
                onPressed: onApplyFilters,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: const Color(0xFF1477F8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('필터 적용'),
              );

              if (stacked) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: clearButton),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: applyButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: clearButton),
                  const SizedBox(width: 10),
                  Expanded(child: applyButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    IconData? icon,
  }) {
    final c = context.colors;
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: c.subtleBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.borderBlue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.borderBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1477F8), width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        side: BorderSide(color: c.borderBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: c.textSecondary,
      ),
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(
        date == null ? label : '${date!.year}.${date!.month}.${date!.day}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AuditEmptyCard extends StatelessWidget {
  const _AuditEmptyCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 28,
            color: c.iconSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            '로그가 없습니다.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textBody,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _AuditMeta({required this.icon, required this.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: c.iconSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              color: c.textSecondary,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AdminAuditLogModel log;

  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _actionColor(log.action);
    return Material(
      color: Colors.transparent,
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
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(_actionIcon(log.action), color: color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _actionLabel(log.action),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: color,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(log.createdAt),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 11,
                          color: c.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_targetLabel(log.targetType)} #${log.targetId}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      if (_canOpenTarget(log))
                        TextButton.icon(
                          onPressed: () => _openTarget(context, log),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: Text('이동'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _AuditMeta(
                    icon: Icons.person_outline_rounded,
                    text: '처리자: ${log.adminNickname}',
                  ),
                  if (log.ipAddress != null &&
                      log.ipAddress!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _AuditMeta(
                      icon: Icons.language_rounded,
                      text: 'IP: ${log.ipAddress}',
                    ),
                  ],
                  if (log.userAgent != null &&
                      log.userAgent!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _AuditMeta(
                      icon: Icons.devices_rounded,
                      text: 'User-Agent: ${log.userAgent}',
                      maxLines: 2,
                    ),
                  ],
                  if (log.reason != null && log.reason!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      log.reason!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        color: c.textBody,
                        height: 1.45,
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

  bool _canOpenTarget(AdminAuditLogModel log) =>
      log.targetType == 'POST' ||
      log.targetType == 'REPORT' ||
      log.targetType == 'PENALTY' ||
      _commentPostId(log) != null;

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
        context.push(
          AppRoutes.adminPostDetail(postId),
          extra: {'focusCommentId': log.targetId},
        );
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
    if (action.contains('APPROVE') || action.contains('WARN')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF426C82);
  }

  IconData _actionIcon(String action) {
    if (action.contains('HIDE')) return Icons.visibility_off_outlined;
    if (action.contains('RESTORE')) return Icons.restore_rounded;
    if (action.contains('APPROVE')) return Icons.check_circle_outline_rounded;
    if (action.contains('REJECT')) return Icons.block_rounded;
    if (action.contains('WARN')) return Icons.warning_amber_rounded;
    if (action.contains('VIEW')) return Icons.visibility_outlined;
    return Icons.history_rounded;
  }

  String _actionLabel(String action) => switch (action) {
    'VIEW_POST_DETAIL' => '상세 열람',
    'HIDE_POST' => '게시글 숨김',
    'RESTORE_POST' => '게시글 복구',
    'HIDE_COMMENT' => '댓글 숨김',
    'RESTORE_COMMENT' => '댓글 복구',
    'APPROVE_REPORT' => '신고 승인',
    'REJECT_REPORT' => '신고 거절',
    'WARN_REPORT' => '경고 처리',
    'CANCEL_PENALTY' => '제재 취소',
    'VIEW_VERIFICATION_REQUEST' => '인증 상세 열람',
    'APPROVE_VERIFICATION_REQUEST' => '인증 승인',
    'REJECT_VERIFICATION_REQUEST' => '인증 거절',
    'VIEW_INQUIRY_DETAIL' => '문의 상세 열람',
    'ANSWER_INQUIRY' => '문의 답변',
    _ => action,
  };

  String _targetLabel(String targetType) => switch (targetType) {
    'POST' => '게시글',
    'COMMENT' => '댓글',
    'REPORT' => '신고',
    'PENALTY' => '제재',
    'VERIFICATION_REQUEST' => '인증 요청',
    'INQUIRY' => '문의',
    _ => targetType,
  };

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
