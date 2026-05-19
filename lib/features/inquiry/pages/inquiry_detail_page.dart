import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                state.error ?? '문의 내용을 불러오지 못했습니다.',
                style: AppTextStyles.bodyMedium.copyWith(color: c.textMuted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      children: [
                        // 히어로 카드: 목록 페이지와 동일한 그라디언트·일러스트 구조
                        _DetailHeroCard(inquiry: inquiry),
                        const SizedBox(height: 16),
                        _QuestionPanel(inquiry: inquiry),
                        const _FlowGap(),
                        _AnswerPanel(inquiry: inquiry),
                        const SizedBox(height: 28),
                        // 하단 액션 버튼
                        _BottomActions(inquiryId: inquiry.inquiryId),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// 상단 히어로 카드 — 목록 페이지(_InquiryHeroCard)와 동일한 그라디언트·테두리·말풍선 일러스트
class _DetailHeroCard extends StatelessWidget {
  final InquiryDetailModel inquiry;

  const _DetailHeroCard({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, compact ? 18 : 22, 18, compact ? 16 : 20),
          decoration: BoxDecoration(
            // 목록 페이지와 동일한 파란 그라디언트
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4FAFF), Color(0xFFEAF6FF)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFDCEEFF)),
          ),
          child: Stack(
            children: [
              // 말풍선 일러스트 — 목록 페이지와 동일한 위치·스케일
              Positioned(
                right: compact ? -10 : 0,
                top: compact ? 0 : 4,
                child: Transform.scale(
                  scale: compact ? 0.62 : 0.76,
                  alignment: Alignment.topRight,
                  child: const _BubbleGraphic(),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: compact ? 72 : 116),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadge(answered: inquiry.isAnswered),
                    const SizedBox(height: 12),
                    Text(
                      inquiry.title,
                      style: AppTextStyles.displaySmall.copyWith(
                        // 작성·목록 페이지와 동일한 compact 분기
                        fontSize: compact ? 15 : 17,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                        letterSpacing: 0,
                        color: c.textPrimary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: c.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '문의일 · ${_fmtDate(inquiry.createdAt)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 11,
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // yyyy.mm.dd 포맷
  String _fmtDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

// 목록 페이지(_InquiryBubbleGraphic)와 완전히 동일한 말풍선 일러스트
class _BubbleGraphic extends StatelessWidget {
  const _BubbleGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 92,
      child: Stack(
        children: [
          Positioned(
            right: 28,
            top: 0,
            child: Container(
              width: 76,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7EB3FF), Color(0xFF4D8EF7)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B83F6).withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(),
                  SizedBox(width: 7),
                  _Dot(),
                  SizedBox(width: 7),
                  _Dot(),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 10,
            child: Container(
              width: 60,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 13,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                '?',
                style: AppTextStyles.displaySmall.copyWith(
                  color: const Color(0xFF7C91AA),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
    );
  }
}

// 문의 내용 패널
class _QuestionPanel extends StatelessWidget {
  final InquiryDetailModel inquiry;

  const _QuestionPanel({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.chat_bubble_outline_rounded,
            label: '문의 내용',
          ),
          const SizedBox(height: 14),
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
                height: 1.6,
                color: c.textBody,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 작성 시각 우측 정렬
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.schedule_rounded, size: 11, color: c.textTertiary),
              const SizedBox(width: 3),
              Text(
                formatDateTime(inquiry.createdAt),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 10,
                  color: c.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 답변 패널 — 답변 완료 시 tinted, 대기 중엔 빈 상태 UI
class _AnswerPanel extends StatelessWidget {
  final InquiryDetailModel inquiry;

  const _AnswerPanel({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasAnswer =
        inquiry.adminAnswer != null && inquiry.adminAnswer!.trim().isNotEmpty;

    return _Panel(
      tinted: hasAnswer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.support_agent_rounded,
            label: '답변 내용',
            iconColor: Color(0xFF2B83F6),
          ),
          const SizedBox(height: 14),
          if (hasAnswer) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.borderBlue),
              ),
              child: Text(
                inquiry.adminAnswer!.trim(),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  height: 1.6,
                  color: c.textBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (inquiry.answeredAt != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.schedule_rounded, size: 11, color: c.textTertiary),
                  const SizedBox(width: 3),
                  Text(
                    '답변일 · ${_fmtDate(inquiry.answeredAt!)} · ${_fmtTime(inquiry.answeredAt!)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 10,
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ] else
            // 답변 대기 빈 상태
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 20,
                      color: Color(0xFF2B83F6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '답변을 준비하고 있어요',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '빠른 시일 내에 답변 드리겠습니다.',
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
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  // 오전/오후 hh:mm 포맷 (스크린샷 형식 일치)
  String _fmtTime(DateTime dt) {
    final ampm = dt.hour < 12 ? '오전' : '오후';
    final h = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$ampm $h:$m';
  }
}

// 카드 패널 공통 — 그림자·둥근 모서리, write 페이지의 _InputPanel과 동일 스타일
class _Panel extends StatelessWidget {
  final Widget child;
  final bool tinted;

  const _Panel({required this.child, this.tinted = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: tinted ? c.tintBg : c.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tinted ? c.borderBlue : c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// 섹션 레이블 — write 페이지의 _FieldLabel과 동일한 아이콘+텍스트 구조
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _SectionLabel({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = iconColor ?? const Color(0xFF2B83F6);

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}

// 상태 뱃지 — 목록 페이지(_InquiryStatusBadge)와 동일한 초록/주황 색상 계열
class _StatusBadge extends StatelessWidget {
  final bool answered;

  const _StatusBadge({required this.answered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: answered ? const Color(0xFFEAF8F0) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: answered ? const Color(0xFFB7E4C7) : const Color(0xFFFFD8A8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: answered ? const Color(0xFF1F8F4D) : const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            answered ? '답변 완료' : '답변 대기',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: answered ? const Color(0xFF1F8F4D) : const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}

// 질문↔답변 연결선 — 위에서 아래로 흐리는 파란 그라디언트 수직선
class _FlowGap extends StatelessWidget {
  const _FlowGap();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Center(
        child: Container(
          width: 2,
          height: 20,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x802B83F6), Color(0x262B83F6)],
            ),
          ),
        ),
      ),
    );
  }
}

// 하단 액션 버튼 — 문의 목록으로 텍스트 링크
class _BottomActions extends StatelessWidget {
  final int inquiryId;

  const _BottomActions({required this.inquiryId});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GestureDetector(
      onTap: () => context.pop(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '문의 목록으로',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(width: 3),
          Icon(Icons.chevron_right_rounded, size: 16, color: c.textSecondary),
        ],
      ),
    );
  }
}
