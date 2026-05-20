import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_format.dart';
import '../models/inquiry_model.dart';
import '../provider/inquiry_provider.dart';

class InquiryDetailPage extends ConsumerStatefulWidget {
  final int inquiryId;

  const InquiryDetailPage({super.key, required this.inquiryId});

  @override
  ConsumerState<InquiryDetailPage> createState() => _InquiryDetailPageState();
}

class _InquiryDetailPageState extends ConsumerState<InquiryDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(inquiryDetailProvider(widget.inquiryId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inquiryDetailProvider(widget.inquiryId));
    final inquiry = state.inquiry;
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '문의 상세',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      children: [
                        _QuestionPanel(inquiry: inquiry),
                        const _FlowGap(),
                        _AnswerPanel(answer: inquiry.adminAnswer),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  final InquiryDetailModel inquiry;

  const _QuestionPanel({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _DetailPanel(
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
          const SizedBox(height: 14),
          Text(
            inquiry.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 17,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.subtleBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: Text(
              inquiry.content,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                height: 1.55,
                color: c.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerPanel extends StatelessWidget {
  final String? answer;

  const _AnswerPanel({required this.answer});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasAnswer = answer != null && answer!.trim().isNotEmpty;
    return _DetailPanel(
      tinted: hasAnswer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                size: 18,
                color: Color(0xFF14A3F7),
              ),
              const SizedBox(width: 8),
              Text(
                '운영팀 답변',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasAnswer ? c.cardBg : c.subtleBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: hasAnswer ? c.borderBlue : c.border),
            ),
            child: Text(
              hasAnswer ? answer!.trim() : '아직 답변을 준비하고 있습니다.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                height: 1.55,
                color: hasAnswer ? c.textBody : c.textMuted,
                fontWeight: hasAnswer ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final Widget child;
  final bool tinted;

  const _DetailPanel({required this.child, this.tinted = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tinted ? c.tintBg : c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tinted ? c.borderBlue : c.borderStrong),
      ),
      child: child,
    );
  }
}

class _FlowGap extends StatelessWidget {
  const _FlowGap();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 18,
      child: Center(
        child: Container(width: 2, height: 18, color: c.borderBlue),
      ),
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
