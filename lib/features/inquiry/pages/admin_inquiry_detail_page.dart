import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../provider/admin_inquiry_provider.dart';

class AdminInquiryDetailPage extends ConsumerStatefulWidget {
  final int inquiryId;

  const AdminInquiryDetailPage({super.key, required this.inquiryId});

  @override
  ConsumerState<AdminInquiryDetailPage> createState() =>
      _AdminInquiryDetailPageState();
}

class _AdminInquiryDetailPageState
    extends ConsumerState<AdminInquiryDetailPage> {
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(adminInquiryDetailProvider(widget.inquiryId).notifier)
          .load(),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminInquiryDetailProvider(widget.inquiryId));
    final inquiry = state.inquiry;
    final c = context.colors;

    ref.listen(adminInquiryDetailProvider(widget.inquiryId), (_, next) {
      if (next.answered) {
        showAppSnackBar('답변을 등록했어요.');
        Navigator.of(context).pop(true);
      }
      if (next.error != null) {
        showAppSnackBar(next.error!, backgroundColor: const Color(0xFFE05C7B));
      }
    });

    final isPending = inquiry?.status == 'PENDING';

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(
          '문의 상세',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: state.isLoading && inquiry == null
          ? const Center(child: CircularProgressIndicator())
          : inquiry == null
          ? Center(
              child: Text(
                state.error ?? '문의 내용을 불러오지 못했어요.',
                style: AppTextStyles.bodyMedium.copyWith(color: c.textMuted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _InquirySummaryHeader(
                  answered: inquiry.isAnswered,
                  title: inquiry.title,
                  userLine: _userLine(
                    inquiry.userName,
                    inquiry.userNickname,
                    inquiry.schoolName,
                  ),
                ),
                const SizedBox(height: 12),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusBadge(answered: inquiry.isAnswered),
                          const Spacer(),
                          Text(
                            timeAgo(inquiry.createdAt),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 11,
                              color: c.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _MetaRow(label: '실명', value: inquiry.userName ?? ''),
                      const SizedBox(height: 7),
                      _MetaRow(label: '닉네임', value: inquiry.userNickname ?? ''),
                      const SizedBox(height: 7),
                      _MetaRow(label: '학교', value: inquiry.schoolName ?? ''),
                      const SizedBox(height: 12),
                      Text(
                        inquiry.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        inquiry.content,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          height: 1.55,
                          color: c.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Panel(
                  child: isPending
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '답변 작성',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _answerController,
                              minLines: 6,
                              maxLines: 10,
                              maxLength: 2000,
                              decoration: InputDecoration(
                                hintText: '사용자에게 전달할 답변을 입력하세요.',
                                filled: true,
                                fillColor: c.subtleBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.all(13),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: state.isAnswering ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1477F8),
                                  disabledBackgroundColor: const Color(
                                    0xFFBFC8FF,
                                  ),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (state.isAnswering) ...[
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ] else ...[
                                      const Icon(Icons.send_rounded, size: 18),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      state.isAnswering ? '등록 중...' : '답변 등록',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '등록된 답변',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              inquiry.adminAnswer ?? '',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                height: 1.55,
                                color: c.textBody,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  void _submit() {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      showAppSnackBar('답변 내용을 입력해 주세요.');
      return;
    }
    ref
        .read(adminInquiryDetailProvider(widget.inquiryId).notifier)
        .answer(answer);
  }

  String _userLine(String? name, String? nickname, String? school) {
    final identity = [
      if ((name ?? '').trim().isNotEmpty) name!.trim(),
      if ((nickname ?? '').trim().isNotEmpty) nickname!.trim(),
    ].join(' · ');
    final schoolName = (school ?? '').trim();
    if (schoolName.isEmpty) return identity.isEmpty ? '사용자 정보 없음' : identity;
    if (identity.isEmpty) return schoolName;
    return '$identity · $schoolName';
  }
}

class _InquirySummaryHeader extends StatelessWidget {
  final bool answered;
  final String title;
  final String userLine;

  const _InquirySummaryHeader({
    required this.answered,
    required this.title,
    required this.userLine,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.tintBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFF1477F8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userLine,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusBadge(answered: answered),
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
      ),
      child: child,
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 11,
            color: c.textTertiary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool answered;

  const _StatusBadge({required this.answered});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: answered ? c.tintBg : c.subtleBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: answered ? c.borderBlue : c.border),
      ),
      child: Text(
        answered ? '답변 완료' : '답변 대기',
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: answered ? const Color(0xFF14A3F7) : c.textMuted,
        ),
      ),
    );
  }
}
