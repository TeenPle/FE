import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../models/report_summary_model.dart';
import '../provider/admin_report_provider.dart';

class AdminReportDetailPage extends ConsumerStatefulWidget {
  final int reportId;

  const AdminReportDetailPage({super.key, required this.reportId});

  @override
  ConsumerState<AdminReportDetailPage> createState() =>
      _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends ConsumerState<AdminReportDetailPage> {
  final _penaltyController = TextEditingController(text: '7');
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(adminReportDetailProvider(widget.reportId).notifier).load(),
    );
  }

  @override
  void dispose() {
    _penaltyController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportDetailProvider(widget.reportId));
    final c = context.colors;

    ref.listen(adminReportDetailProvider(widget.reportId), (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!)));
        Navigator.of(context).pop(true);
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFE05C7B),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(
          '신고 상세',
          style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.detail == null
          ? Center(
              child: Text(state.error!, style: TextStyle(color: c.textMuted)),
            )
          : state.detail == null
          ? const SizedBox()
          : _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, AdminReportDetailState state) {
    final detail = state.detail!;
    final isPending = detail.status == 'PENDING';
    final c = context.colors;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ReportSummaryHeader(
                detail: detail,
                onOpenUserHistory: () => context.push(
                  AppRoutes.adminUserHistory(detail.reportedUserId),
                  extra: {'nickname': detail.reportedUserNickname},
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(
                      icon: Icons.receipt_long_outlined,
                      title: '신고 정보',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow('대상', detail.targetTypeLabel),
                    _InfoRow('신고 카테고리', detail.reportReasonLabel),
                    _InfoRow('신고자', detail.reporterNickname),
                    _TappableInfoRow(
                      label: '피신고자',
                      value: detail.reportedUserNickname,
                      onTap: () => context.push(
                        AppRoutes.adminUserHistory(detail.reportedUserId),
                        extra: {'nickname': detail.reportedUserNickname},
                      ),
                    ),
                    if (detail.schoolName != null)
                      _InfoRow('학교', detail.schoolName!),
                    if (detail.boardTitle != null)
                      _InfoRow('게시판', detail.boardTitle!),
                    _InfoRow('신고 일시', _formatDate(detail.createdAt)),
                    if (detail.processedAt != null)
                      _InfoRow('처리 일시', _formatDate(detail.processedAt!)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(
                      icon: Icons.flag_outlined,
                      title: '신고 대상 내용',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detail.targetContent.isEmpty
                          ? '(내용 없음)'
                          : detail.targetContent,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textBody,
                        height: 1.55,
                      ),
                    ),
                    if (detail.postId != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            AppRoutes.adminPostDetail(detail.postId!),
                            extra: detail.targetType == 'COMMENT'
                                ? {'focusCommentId': detail.targetId}
                                : null,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(
                            detail.targetType == 'COMMENT'
                                ? '게시글에서 댓글 확인'
                                : '관리자 게시글 상세 보기',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF426C82),
                            side: const BorderSide(color: Color(0xFF426C82)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isPending) ...[
                const SizedBox(height: 12),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        icon: Icons.edit_note_rounded,
                        title: '처리 입력',
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: '승인, 거절, 경고 처리 사유를 입력하세요.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            width: 96,
                            child: TextField(
                              controller: _penaltyController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: '제재 일수',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '신고 승인 시 입력한 기간만큼 제재가 적용됩니다.',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isPending)
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isActing ? null : () => _onReject(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(state.isActing ? '처리 중...' : '거절'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE05C7B),
                      side: const BorderSide(color: Color(0xFFE05C7B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isActing ? null : () => _onWarn(context),
                    icon: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: Text(state.isActing ? '처리 중...' : '경고'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.isActing
                        ? null
                        : () => _onApprove(context),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(state.isActing ? '처리 중...' : '승인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1477F8),
                      disabledBackgroundColor: const Color(0xFFBFC8FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _onApprove(BuildContext context) {
    final days = int.tryParse(_penaltyController.text.trim());
    final comment = _commentController.text.trim();
    if (days == null || days < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제재 기간을 1일 이상 입력해주세요.')));
      return;
    }
    if (comment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('처리 사유를 입력해주세요.')));
      return;
    }
    _confirm(
      context,
      title: '신고 승인',
      message: '$days일 제재를 적용할까요?',
      onConfirmed: () => ref
          .read(adminReportDetailProvider(widget.reportId).notifier)
          .approve(days, comment),
    );
  }

  void _onReject(BuildContext context) {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('처리 사유를 입력해주세요.')));
      return;
    }
    _confirm(
      context,
      title: '신고 거절',
      message: '이 신고를 거절할까요?',
      onConfirmed: () => ref
          .read(adminReportDetailProvider(widget.reportId).notifier)
          .reject(comment),
    );
  }

  void _onWarn(BuildContext context) {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('처리 사유를 입력해주세요.')));
      return;
    }
    _confirm(
      context,
      title: '경고 발령',
      message: '피신고자에게 경고를 발령할까요?',
      onConfirmed: () => ref
          .read(adminReportDetailProvider(widget.reportId).notifier)
          .warn(comment),
    );
  }

  void _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required Future<bool> Function() onConfirmed,
  }) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: TextStyle(color: ctx.colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onConfirmed();
    });
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ReportSummaryHeader extends StatelessWidget {
  final ReportDetailModel detail;
  final VoidCallback onOpenUserHistory;

  const _ReportSummaryHeader({
    required this.detail,
    required this.onOpenUserHistory,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final processedText = detail.processedAt == null
        ? '아직 처리되지 않은 신고입니다.'
        : '처리 완료 ${_formatDate(detail.processedAt!)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderBlue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1477F8).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.tintBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _statusIcon(detail.status),
                  color: _statusColor(detail.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${detail.targetTypeLabel} 신고',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.reportReasonLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(detail.status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.subtleBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeaderMeta(
                    label: '신고자',
                    value: detail.reporterNickname,
                    c: c,
                  ),
                ),
                Container(width: 1, height: 30, color: c.borderSubtle),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpenUserHistory,
                    child: _HeaderMeta(
                      label: '피신고자',
                      value: detail.reportedUserNickname,
                      c: c,
                      accent: const Color(0xFF1477F8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 15, color: c.iconSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  processedText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _HeaderMeta extends StatelessWidget {
  final String label;
  final String value;
  final AppColors c;
  final Color? accent;

  const _HeaderMeta({
    required this.label,
    required this.value,
    required this.c,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: c.textTertiary)),
          const SizedBox(height: 3),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: accent ?? c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF1477F8)),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: c.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: c.textBody),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) => switch (status) {
  'PENDING' => const Color(0xFF1477F8),
  'RESOLVED' => const Color(0xFF2F7D46),
  'REJECTED' => const Color(0xFFE05C7B),
  'WARNED' => const Color(0xFFF59E0B),
  _ => const Color(0xFF7D8790),
};

IconData _statusIcon(String status) => switch (status) {
  'PENDING' => Icons.hourglass_top_rounded,
  'RESOLVED' => Icons.check_circle_rounded,
  'REJECTED' => Icons.cancel_rounded,
  'WARNED' => Icons.warning_amber_rounded,
  _ => Icons.flag_outlined,
};

class _TappableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TappableInfoRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: c.textTertiary),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF426C82),
                  fontWeight: FontWeight.w700,
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, color, bg) = switch (status) {
      'PENDING' => ('대기 중', const Color(0xFF426C82), const Color(0xFFEAF3FB)),
      'RESOLVED' => ('승인 완료', const Color(0xFF2F7D46), const Color(0xFFE8F5E9)),
      'REJECTED' => ('거절됨', c.textMuted, c.subtleBg),
      'WARNED' => ('경고 발령', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      _ => (status, c.textMuted, c.subtleBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
