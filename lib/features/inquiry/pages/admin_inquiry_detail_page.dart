import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('답변을 등록했습니다.')));
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

    final isPending = inquiry?.status == 'PENDING';

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(
          '문의 상세',
          style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
        ),
      ),
      body: state.isLoading && inquiry == null
          ? const Center(child: CircularProgressIndicator())
          : inquiry == null
          ? Center(
              child: Text(
                state.error ?? '문의 내용을 불러오지 못했습니다.',
                style: TextStyle(color: c.textMuted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
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
                            style: TextStyle(
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
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        inquiry.content,
                        style: TextStyle(
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
                              style: TextStyle(
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
                              height: 48,
                              child: ElevatedButton(
                                onPressed: state.isAnswering ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF14A3F7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  state.isAnswering ? '등록 중...' : '답변 등록',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
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
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              inquiry.adminAnswer ?? '',
                              style: TextStyle(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('답변 내용을 입력해주세요.')));
      return;
    }
    ref
        .read(adminInquiryDetailProvider(widget.inquiryId).notifier)
        .answer(answer);
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
        Text(label, style: TextStyle(fontSize: 11, color: c.textTertiary)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: answered ? const Color(0xFF14A3F7) : c.textMuted,
        ),
      ),
    );
  }
}
