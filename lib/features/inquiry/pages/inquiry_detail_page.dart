import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        children: [
                          // 디자인 시안의 큰 상태 요약 카드 역할입니다.
                          // 좁은 기기에서도 제목 영역과 일러스트가 겹치지 않도록
                          // LayoutBuilder에서 여백과 크기를 분기합니다.
                          _DetailHeroCard(inquiry: inquiry),
                          const SizedBox(height: 18),
                          _QuestionPanel(inquiry: inquiry),
                          const SizedBox(height: 14),
                          _AnswerPanel(inquiry: inquiry),
                          const SizedBox(height: 20),
                          const _BottomActions(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final titleSize = compact ? 15.0 : 17.0;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: compact ? 138 : 150),
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 20,
            compact ? 15 : 18,
            compact ? 16 : 18,
            compact ? 15 : 18,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF182334), Color(0xFF132033)]
                  : const [Color(0xFFF5FAFF), Color(0xFFEAF5FF)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? c.borderBlue : const Color(0xFFE4F0FD),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B83F6).withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: compact ? -10 : 0,
                bottom: compact ? 2 : 4,
                child: Transform.scale(
                  scale: compact ? 0.46 : 0.54,
                  alignment: Alignment.bottomRight,
                  child: const _BubbleGraphic(),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: compact ? 62 : 86),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusBadge(answered: inquiry.isAnswered),
                    SizedBox(height: compact ? 12 : 14),
                    Text(
                      inquiry.title,
                      style: AppTextStyles.displaySmall.copyWith(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                        letterSpacing: 0,
                        color: c.textPrimary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '문의일 · ${_fmtDate(inquiry.createdAt)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: compact ? 11 : 12,
                            color: c.textSecondary,
                            fontWeight: FontWeight.w600,
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
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.chat_bubble_outline_rounded,
            label: '문의 내용',
          ),
          const SizedBox(height: 12),
          _MessageBox(
            body: inquiry.content,
            footerItems: [
              _MetaItem(
                icon: Icons.schedule_rounded,
                text: _fmtTime(inquiry.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final ampm = dt.hour < 12 ? '오전' : '오후';
    final h = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(
      2,
      '0',
    );
    final m = dt.minute.toString().padLeft(2, '0');
    return '$ampm $h:$m';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.support_agent_rounded,
            label: '답변 내용',
            iconColor: Color(0xFF2B83F6),
          ),
          const SizedBox(height: 12),
          if (hasAnswer) ...[
            _MessageBox(
              body: inquiry.adminAnswer!.trim(),
              tinted: true,
              footerItems: [
                if (inquiry.answeredAt != null)
                  _MetaItem(
                    icon: Icons.calendar_today_rounded,
                    text: '답변일  ${_fmtDate(inquiry.answeredAt!)}',
                  ),
                if (inquiry.answeredAt != null)
                  _MetaItem(
                    icon: Icons.schedule_rounded,
                    text: _fmtTime(inquiry.answeredAt!),
                  ),
              ],
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: c.subtleBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '빠른 시일 내에 답변 드리겠습니다.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11,
                      height: 1.5,
                      color: c.textMuted,
                    ),
                    textAlign: TextAlign.center,
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
    final h = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(
      2,
      '0',
    );
    final m = dt.minute.toString().padLeft(2, '0');
    return '$ampm $h:$m';
  }
}

// 카드 패널 공통 — 그림자·둥근 모서리, write 페이지의 _InputPanel과 동일 스타일
class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234160).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String body;
  final List<_MetaItem> footerItems;
  final bool tinted;

  const _MessageBox({
    required this.body,
    required this.footerItems,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tinted
            ? (isDark ? c.subtleBg : const Color(0xFFFAFDFF))
            : c.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tinted
              ? (isDark ? c.borderBlue : const Color(0xFFDCEAFF))
              : c.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                height: 1.65,
                color: c.textBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (footerItems.isNotEmpty) ...[
            Container(
              height: 1,
              color: tinted
                  ? (isDark ? c.borderBlue : const Color(0xFFE4F0FF))
                  : c.border,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  for (final item in footerItems) ...[
                    if (item != footerItems.first) const Spacer(),
                    item,
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Flexible(
      fit: FlexFit.loose,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c.iconSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: c.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 11),
        Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            fontSize: 14,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: answered
            ? (isDark ? const Color(0xFF12352F) : const Color(0xFFDFF8F4))
            : (isDark ? const Color(0xFF3A2A13) : const Color(0xFFFFF4E5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: answered
                  ? const Color(0xFF19A695)
                  : const Color(0xFFD97706),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            answered ? '답변 완료' : '답변 대기',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: answered
                  ? (isDark ? const Color(0xFF5FE0CF) : const Color(0xFF0C9A8A))
                  : (isDark
                        ? const Color(0xFFFFC46B)
                        : const Color(0xFFD97706)),
            ),
          ),
        ],
      ),
    );
  }
}

// 하단 액션 버튼 — 문의 목록으로 텍스트 링크
class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.inquiryWrite),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
            label: Text(
              '추가 문의하기',
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF187BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF187BFF),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '문의 목록으로',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF187BFF),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF187BFF),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
