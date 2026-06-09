import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../provider/find_password_provider.dart';

class FindPasswordPage extends ConsumerStatefulWidget {
  const FindPasswordPage({super.key});

  @override
  ConsumerState<FindPasswordPage> createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends ConsumerState<FindPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _hasSentCode = false;
  int _remainingSeconds = 180;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _remainingSeconds = 180);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    ref.read(findPasswordProvider.notifier).resetVerify();
    _codeController.clear();

    await ref.read(findPasswordProvider.notifier).sendCode(email);

    if (!mounted) return;
    if (ref.read(findPasswordProvider).isSendSuccess) {
      setState(() => _hasSentCode = true);
      _startCountdown();
    }
  }

  Future<void> _verifyCode() async {
    await ref
        .read(findPasswordProvider.notifier)
        .verifyCode(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
        );

    if (!mounted) return;
    if (ref.read(findPasswordProvider).isVerified) {
      _countdownTimer?.cancel();
      setState(() {});
    }
  }

  bool get _isValidEmail {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(_emailController.text.trim());
  }

  bool get _isValidCode =>
      RegExp(r'^\d{6}$').hasMatch(_codeController.text.trim());

  bool get _isExpired => _hasSentCode && _remainingSeconds == 0;

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData icon,
  }) {
    final c = context.colors;
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.captionLarge.copyWith(color: c.textHint),
      filled: true,
      fillColor: c.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      prefixIcon: Icon(icon, color: context.colors.iconSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF4A67F2), width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(findPasswordProvider);
    final isVerified = state.isVerified;
    final isExpired = _isExpired && !isVerified;

    final canSend = _isValidEmail && !state.isSendLoading;
    final canVerify =
        _isValidCode && !state.isVerifyLoading && !isExpired && !isVerified;

    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.viewPadding.bottom;
    final bottomPad = keyboard > 0
        ? keyboard + 8.0
        : safeBottom + (media.size.height * 0.024).clamp(14.0, 24.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: context.colors.pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
                icon: Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),

              SizedBox(height: 16),

              Text(
                '비밀번호 찾기',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Color(0xFF4A67F2),
                ),
              ),

              SizedBox(height: 8),

              Text(
                '가입한 이메일로\n인증번호를 받아주세요.',
                style: AppTextStyles.displaySmall.copyWith(
                  height: 1.3,
                  letterSpacing: -0.5,
                  color: context.colors.textPrimary,
                ),
              ),

              SizedBox(height: 32),

              Text(
                '이메일',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
              SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !_hasSentCode,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(
                        context,
                        hintText: '가입한 이메일을 입력해 주세요.',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                  ),
                  if (_hasSentCode) ...[
                    SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isSendLoading ? null : _sendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A67F2),
                          disabledBackgroundColor: const Color(0xFFD7DEFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          state.isSendLoading ? '전송 중' : '재전송',
                          style: AppTextStyles.labelMedium,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: 8),

              if (state.sendError != null)
                Text(
                  state.sendError!,
                  style: AppTextStyles.captionSmall.copyWith(color: Colors.red),
                )
              else if (isVerified)
                Text(
                  '인증이 완료된 이메일이에요.',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: Color(0xFF4A67F2),
                  ),
                )
              else if (_hasSentCode)
                Text(
                  '인증번호를 전송했어요.',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: context.colors.textMuted,
                  ),
                )
              else
                Text(
                  '인증번호는 3분 동안 유효해요.',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),

              if (_hasSentCode) ...[
                SizedBox(height: 24),

                Text(
                  '인증번호',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
                SizedBox(height: 8),

                if (isVerified)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4A67F2),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: Color(0xFF4A67F2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          '이메일 인증이 완료되었어요.',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            ref
                                .read(findPasswordProvider.notifier)
                                .resetVerify();
                            setState(() {});
                          },
                          decoration: _inputDecoration(
                            context,
                            hintText: '6자리 인증번호',
                            icon: Icons.verified_outlined,
                          ).copyWith(counterText: ''),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: canVerify ? _verifyCode : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A67F2),
                            disabledBackgroundColor: const Color(0xFFD7DEFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            state.isVerifyLoading ? '확인 중' : '확인',
                            style: AppTextStyles.labelMedium,
                          ),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 8),

                if (!isVerified)
                  Text(
                    isExpired
                        ? '인증 시간이 만료되었어요.'
                        : '남은 시간 ${_formatTime(_remainingSeconds)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isExpired ? Colors.red : const Color(0xFF4A67F2),
                    ),
                  ),

                if (state.verifyError != null) ...[
                  SizedBox(height: 4),
                  Text(
                    state.verifyError!,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ],
            ),
          ),
        ),
        AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isVerified
                    ? () {
                        context.push(
                          AppRoutes.resetPassword,
                          extra: state.verificationToken!,
                        );
                      }
                    : (!_hasSentCode && canSend)
                    ? _sendCode
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A67F2),
                  disabledBackgroundColor: const Color(0xFFD7DEFF),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isVerified
                      ? '다음'
                      : (state.isSendLoading
                            ? '전송 중...'
                            : (_hasSentCode ? '인증 완료 후 다음' : '인증번호 받기')),
                  style: AppTextStyles.titleSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
