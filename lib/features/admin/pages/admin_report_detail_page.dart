import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../provider/admin_report_provider.dart';

class AdminReportDetailPage extends ConsumerStatefulWidget {
  final int reportId;

  const AdminReportDetailPage({super.key, required this.reportId});

  @override
  ConsumerState<AdminReportDetailPage> createState() =>
      _AdminReportDetailPageState();
}

class _AdminReportDetailPageState
    extends ConsumerState<AdminReportDetailPage> {
  final _penaltyController = TextEditingController(text: '7');
  final _warningCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(adminReportDetailProvider(widget.reportId).notifier)
        .load());
  }

  @override
  void dispose() {
    _penaltyController.dispose();
    _warningCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportDetailProvider(widget.reportId));

    ref.listen(adminReportDetailProvider(widget.reportId), (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('신고 상세',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.detail == null
              ? Center(
                  child: Text(state.error!,
                      style: const TextStyle(color: Colors.grey)))
              : state.detail == null
                  ? const SizedBox()
                  : _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, AdminReportDetailState state) {
    final detail = state.detail!;
    final isPending = detail.status == 'PENDING';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 뱃지
                _StatusBadge(detail.status),
                const SizedBox(height: 20),

                // 신고 정보
                _SectionTitle('신고 정보'),
                const SizedBox(height: 12),
                _InfoRow('대상', detail.targetTypeLabel),
                _InfoRow('신고 사유', detail.reportReasonLabel),
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
                const SizedBox(height: 24),

                // 신고된 내용
                _SectionTitle('신고된 내용'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: Text(
                    detail.targetContent.isEmpty
                        ? '(내용 없음)'
                        : detail.targetContent,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                        height: 1.6),
                  ),
                ),
                if (detail.targetType == 'POST') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.adminPostDetail(detail.targetId),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('관리자 게시글 상세 보기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5A8EA8),
                        side: const BorderSide(color: Color(0xFFBBD3DF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // 처리 옵션 (PENDING일 때만)
                if (isPending) ...[
                  _SectionTitle('제재 기간'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _penaltyController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFDDE6ED)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF5A8EA8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('일',
                          style: TextStyle(
                              fontSize: 15, color: Color(0xFF6B7C8A))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('경고 코멘트'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _warningCommentController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: '경고 사유 및 안내 사항을 입력하세요.\n(경고를 선택할 경우 유저에게 이 내용이 표시됩니다.)',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFFB0BEC5), height: 1.5),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFDDE6ED)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFF59E0B)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 하단 버튼 (PENDING일 때만)
        if (isPending)
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 경고 섹션
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      const Text('경고',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B))),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Divider(
                              color: Color(0xFFFCD34D), thickness: 1)),
                    ],
                  ),
                ),
                // 경고 버튼 (전체 너비)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: state.isActing
                        ? null
                        : () => _onWarn(context),
                    icon: const Icon(Icons.warning_amber_rounded,
                        size: 18, color: Color(0xFFF59E0B)),
                    label: Text(
                      state.isActing ? '처리 중...' : '경고 발령',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 제재 섹션
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_rounded,
                          size: 13, color: Color(0xFF5A8EA8)),
                      const SizedBox(width: 4),
                      const Text('제재',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5A8EA8))),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Divider(
                              color: Color(0xFFDDE6ED), thickness: 1)),
                    ],
                  ),
                ),
                // 거절 / 승인(제재) 버튼
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: state.isActing
                              ? null
                              : () => _onReject(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE05C7B),
                            side: const BorderSide(color: Color(0xFFE05C7B)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                              state.isActing ? '처리 중...' : '거절',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: state.isActing
                              ? null
                              : () => _onApprove(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A8EA8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                              state.isActing ? '처리 중...' : '승인 (제재 적용)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _onApprove(BuildContext context) {
    final days = int.tryParse(_penaltyController.text.trim());
    if (days == null || days < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제재 기간을 1일 이상 입력해주세요.')),
      );
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('신고 승인'),
        content: Text('${days}일 제재를 적용하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('승인',
                style: TextStyle(color: Color(0xFF5A8EA8))),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref
            .read(adminReportDetailProvider(widget.reportId).notifier)
            .approve(days);
      }
    });
  }

  void _onWarn(BuildContext context) {
    final comment = _warningCommentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('경고 코멘트를 입력해주세요.')),
      );
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('경고 발령'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('아래 코멘트로 경고를 발령하시겠어요?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Text(
                comment,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF78350F), height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('경고 발령',
                style: TextStyle(color: Color(0xFFF59E0B))),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref
            .read(adminReportDetailProvider(widget.reportId).notifier)
            .warn(comment);
      }
    });
  }

  void _onReject(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('신고 거절'),
        content: const Text('이 신고를 거절하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('거절',
                style: TextStyle(color: Color(0xFFE05C7B))),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref
            .read(adminReportDetailProvider(widget.reportId).notifier)
            .reject();
      }
    });
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7C8A)));
  }
}

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF9AA7B2))),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5A8EA8),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF9AA7B2))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333))),
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
    final (label, color, bg) = switch (status) {
      'PENDING'  => ('대기 중',   const Color(0xFF5A8EA8), const Color(0xFFEAF3FB)),
      'RESOLVED' => ('제재 완료', const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      'REJECTED' => ('거절됨',   const Color(0xFF9AA7B2), const Color(0xFFF0F0F0)),
      'WARNED'   => ('경고 발령', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      _ => (status, Colors.grey, const Color(0xFFF0F0F0)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
