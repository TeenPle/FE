import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../models/inquiry_model.dart';
import '../provider/inquiry_provider.dart';

class InquiryPage extends ConsumerStatefulWidget {
  const InquiryPage({super.key});

  @override
  ConsumerState<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends ConsumerState<InquiryPage> {
  _InquiryFilter _filter = _InquiryFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(inquiryListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inquiryListProvider);
    final c = context.colors;
    final visibleInquiries = state.inquiries.where((item) {
      return switch (_filter) {
        _InquiryFilter.all => true,
        _InquiryFilter.pending => !item.isAnswered,
        _InquiryFilter.answered => item.isAnswered,
      };
    }).toList();

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '문의하기',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inquiryListProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _InquiryHeroCard(
              onTap: () async {
                final created = await context.push<bool>(
                  AppRoutes.inquiryWrite,
                );
                if (created == true && context.mounted) {
                  ref.read(inquiryListProvider.notifier).load();
                  showAppSnackBar('문의가 등록되었습니다.');
                }
              },
            ),
            const SizedBox(height: 28),
            _InquirySectionHeader(
              total: state.inquiries.length,
              pending: state.inquiries.where((item) => !item.isAnswered).length,
              answered: state.inquiries.where((item) => item.isAnswered).length,
              selected: _filter,
              onChanged: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.inquiries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null)
              _InquiryEmptyState(text: state.error!)
            else if (state.inquiries.isEmpty)
              const _InquiryEmptyState(text: '아직 문의 내역이 없어요.')
            else if (visibleInquiries.isEmpty)
              const _InquiryEmptyState(text: '선택한 상태의 문의가 없어요.')
            else
              ...visibleInquiries.map(
                (inquiry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InquiryListTile(
                    inquiry: inquiry,
                    onTap: () async {
                      await context.push(
                        AppRoutes.inquiryDetail(inquiry.inquiryId),
                      );
                      if (context.mounted) {
                        ref.read(inquiryListProvider.notifier).load();
                      }
                    },
                  ),
                ),
              ),
            const SizedBox(height: 18),
            const _InquiryNoticeCard(),
          ],
        ),
      ),
    );
  }
}

enum _InquiryFilter { all, pending, answered }

class _InquiryHeroCard extends StatelessWidget {
  final VoidCallback onTap;

  const _InquiryHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(18, compact ? 18 : 20, 18, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF182334), Color(0xFF132033)]
                      : const [Color(0xFFF4FAFF), Color(0xFFEAF6FF)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? c.borderBlue : const Color(0xFFDCEEFF),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned(
                          right: compact ? -16 : 2,
                          top: compact ? 2 : 8,
                          child: Transform.scale(
                            scale: compact ? 0.62 : 0.76,
                            alignment: Alignment.topRight,
                            child: const _InquiryBubbleGraphic(),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: compact ? 72 : 116),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '무엇을 ',
                                      style: TextStyle(color: c.textPrimary),
                                    ),
                                    const TextSpan(
                                      text: '도와드릴까요?',
                                      style: TextStyle(
                                        color: Color(0xFF2B83F6),
                                      ),
                                    ),
                                  ],
                                ),
                                style: AppTextStyles.displaySmall.copyWith(
                                  // 제목 폰트 한 단계 축소: compact 17→15, 일반 19→17
                                  fontSize: compact ? 15 : 17,
                                  fontWeight: FontWeight.w900,
                                  height: 1.25,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '앱 이용 중 불편한 점이나 궁금한 내용을\n빠르게 확인하고 답변해 드릴게요.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: compact ? 9.5 : 10.5,
                                  height: 1.7,
                                  color: c.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InquiryEntryCard(onTap: onTap),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InquiryBubbleGraphic extends StatelessWidget {
  const _InquiryBubbleGraphic();

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
                  _InquiryBubbleDot(),
                  SizedBox(width: 7),
                  _InquiryBubbleDot(),
                  SizedBox(width: 7),
                  _InquiryBubbleDot(),
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

class _InquiryBubbleDot extends StatelessWidget {
  const _InquiryBubbleDot();

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

class _InquiryEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _InquiryEntryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.tintBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_square,
                  color: Color(0xFF2B83F6),
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '새 문의 작성',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '앱 이용 중 불편한 점이나 궁금한 내용을 남겨주세요.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 10,
                        height: 1.45,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InquirySectionHeader extends StatelessWidget {
  final int total;
  final int pending;
  final int answered;
  final _InquiryFilter selected;
  final ValueChanged<_InquiryFilter> onChanged;

  const _InquirySectionHeader({
    required this.total,
    required this.pending,
    required this.answered,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '내 문의 내역',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InquiryFilterChip(
                    label: '전체 ($total)',
                    selected: selected == _InquiryFilter.all,
                    onTap: () => onChanged(_InquiryFilter.all),
                  ),
                  _InquiryFilterChip(
                    label: '답변 대기 ($pending)',
                    selected: selected == _InquiryFilter.pending,
                    onTap: () => onChanged(_InquiryFilter.pending),
                  ),
                  _InquiryFilterChip(
                    label: '답변 완료 ($answered)',
                    selected: selected == _InquiryFilter.answered,
                    onTap: () => onChanged(_InquiryFilter.answered),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InquiryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InquiryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2B83F6) : c.cardBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? const Color(0xFF2B83F6) : c.borderStrong,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InquiryListTile extends StatelessWidget {
  final InquirySummaryModel inquiry;
  final VoidCallback onTap;

  const _InquiryListTile({required this.inquiry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _InquiryStatusBadge(inquiry: inquiry),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo(inquiry.createdAt),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 10,
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
        ),
      ),
    );
  }
}

class _InquiryNoticeCard extends StatelessWidget {
  const _InquiryNoticeCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? c.cardBg : const Color(0xFFF2F9FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? c.border : const Color(0xFFDDEEFF),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B83F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '문의 내용은 운영 확인 후 답변돼요',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '접수된 내용은 답변과 서비스 개선에 필요한 범위에서만 확인합니다.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 10,
                        height: 1.45,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InquiryStatusBadge extends StatelessWidget {
  final InquirySummaryModel inquiry;

  const _InquiryStatusBadge({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final answered = inquiry.isAnswered;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: answered
            ? (isDark ? const Color(0xFF12352F) : const Color(0xFFEAF8F0))
            : (isDark ? const Color(0xFF3A2A13) : const Color(0xFFFFF4E5)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: answered
              ? (isDark ? const Color(0xFF1F6F62) : const Color(0xFFB7E4C7))
              : (isDark ? const Color(0xFF73521E) : const Color(0xFFFFD8A8)),
        ),
      ),
      child: Text(
        inquiry.statusLabel,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: answered
              ? (isDark ? const Color(0xFF5FE0CF) : const Color(0xFF1F8F4D))
              : (isDark ? const Color(0xFFFFC46B) : const Color(0xFFD97706)),
        ),
      ),
    );
  }
}

class _InquiryEmptyState extends StatelessWidget {
  final String text;

  const _InquiryEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 12,
          color: c.textMuted,
        ),
      ),
    );
  }
}
