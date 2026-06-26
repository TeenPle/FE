import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/web_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/external_links.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../provider/inquiry_provider.dart';

class InquiryWritePage extends ConsumerStatefulWidget {
  const InquiryWritePage({super.key});

  @override
  ConsumerState<InquiryWritePage> createState() => _InquiryWritePageState();
}

class _InquiryWritePageState extends ConsumerState<InquiryWritePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inquiryCreateProvider);
    final c = context.colors;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.viewPadding.bottom;
    final bottomPad = keyboard > 0 ? keyboard + 8.0 : safeBottom + 16.0;

    ref.listen(inquiryCreateProvider, (_, next) {
      if (next.submitted) {
        ref.read(inquiryCreateProvider.notifier).clearResult();
        context.pop(true);
      }
      if (next.error != null) {
        showAppSnackBar(next.error!, backgroundColor: const Color(0xFFE05C7B));
      }
    });

    return Scaffold(
      backgroundColor: c.pageBg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '새 문의 작성',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _InquiryWriteHero(),
                        const SizedBox(height: 18),
                        const _InquiryWriteTip(),
                        const SizedBox(height: 18),
                        const _InquiryWebSupportLink(),
                        const SizedBox(height: 18),
                        _InputPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('문의 제목'),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _titleController,
                                maxLength: 100,
                                textInputAction: TextInputAction.next,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 12,
                                  color: c.textPrimary,
                                ),
                                decoration: _inputDecoration(
                                  context,
                                  '제목을 입력해주세요',
                                ).copyWith(counterText: ''),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '핵심 내용을 짧게 적어주세요',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 10,
                                  color: c.textMuted,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Divider(height: 1, color: c.border),
                              const SizedBox(height: 22),
                              const _FieldLabel('문의 내용'),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _contentController,
                                minLines: 8,
                                maxLines: 10,
                                maxLength: 2000,
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 12,
                                  height: 1.55,
                                  color: c.textPrimary,
                                ),
                                decoration:
                                    _inputDecoration(
                                      context,
                                      '문의 내용을 자세히 작성해주세요',
                                    ).copyWith(
                                      counterText: '',
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        14,
                                        14,
                                        14,
                                        42,
                                      ),
                                    ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '상황을 자세히 적어주시면 답변에 도움이 돼요',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontSize: 10,
                                        color: c.textMuted,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_contentController.text.length} / 2000',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: c.textSecondary,
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
              ],
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: state.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1677FF),
                      disabledBackgroundColor: const Color(0xFFBBD6FF),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      state.isSubmitting ? '등록 중...' : '문의 등록',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      showAppSnackBar('제목과 내용을 모두 입력해 주세요.');
      return;
    }
    FocusScope.of(context).unfocus();
    ref
        .read(inquiryCreateProvider.notifier)
        .submit(title: title, content: content);
  }
}

class _InquiryWriteHero extends StatelessWidget {
  const _InquiryWriteHero();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 188 : 210),
          padding: EdgeInsets.fromLTRB(22, compact ? 20 : 24, 22, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF182334), Color(0xFF132033)]
                  : const [Color(0xFFFFFFFF), Color(0xFFF1F7FF)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: compact ? -58 : -34,
                bottom: compact ? -38 : -22,
                child: Transform.scale(
                  scale: compact ? 0.72 : 1,
                  child: const _InquiryWriteBubbleScene(),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: compact ? 58 : 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '불편한 점이나\n',
                            style: TextStyle(color: c.textPrimary),
                          ),
                          const TextSpan(
                            text: '궁금한 내용',
                            style: TextStyle(color: Color(0xFF1677FF)),
                          ),
                          TextSpan(
                            text: '을 남겨주세요',
                            style: TextStyle(color: c.textPrimary),
                          ),
                        ],
                      ),
                      style: AppTextStyles.displaySmall.copyWith(
                        // 제목 폰트 한 단계 축소: compact 17→15, 일반 19→17
                        fontSize: compact ? 15 : 17,
                        fontWeight: FontWeight.w900,
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 18),
                    Text(
                      '자세히 작성해주시면 더 빠르고\n정확하게 도와드릴 수 있어요.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: compact ? 10 : 11,
                        height: 1.65,
                        color: c.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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
}

class _InquiryWriteBubbleScene extends StatelessWidget {
  const _InquiryWriteBubbleScene();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 190,
      height: 160,
      child: Stack(
        children: [
          Positioned(
            right: 4,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.18,
              child: Container(
                width: 90,
                height: 128,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF314158) : Colors.white)
                      .withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            right: 38,
            top: 28,
            child: Container(
              width: 72,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFCEE4FF), Color(0xFFA9CCFF)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1677FF).withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BubbleDot(),
                  SizedBox(width: 7),
                  _BubbleDot(),
                  SizedBox(width: 7),
                  _BubbleDot(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleDot extends StatelessWidget {
  const _BubbleDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _InquiryWriteTip extends StatelessWidget {
  const _InquiryWriteTip();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? c.cardBg : const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isDark ? c.border : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF1677FF),
                shape: BoxShape.circle,
              ),
              child: Text(
                'i',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '빠른 답변을 위해 정확히 작성해주세요',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InquiryWebSupportLink extends StatelessWidget {
  const _InquiryWebSupportLink();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                size: 18,
                color: Color(0xFF1677FF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '이 화면에서 앱 내 문의를 접수할 수 있어요.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '이메일을 통한 자세한 문의가 필요하면 공식 웹 문의 페이지에서 연락처를 확인해 주세요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 10.5,
              height: 1.45,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => openExternalLink(context, teenpleSupportUrl),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1677FF),
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(
              '웹 문의 페이지 보기',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1677FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputPanel extends StatelessWidget {
  final Widget child;

  const _InputPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF1677FF),
            shape: BoxShape.circle,
          ),
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

InputDecoration _inputDecoration(BuildContext context, String hintText) {
  final c = context.colors;
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.bodyMedium.copyWith(
      fontSize: 12,
      color: c.textHint,
    ),
    filled: true,
    fillColor: c.cardBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF1677FF), width: 1.2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
