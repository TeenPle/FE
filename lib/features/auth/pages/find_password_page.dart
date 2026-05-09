import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
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
      if (!mounted) { timer.cancel(); return; }
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
    await ref.read(findPasswordProvider.notifier).verifyCode(
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

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      prefixIcon: Icon(icon, color: const Color(0xFF7A7A7A)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3E7EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3E7EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4A67F2), width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(findPasswordProvider);
    final isVerified = state.isVerified;
    final isExpired = _isExpired && !isVerified;

    final canSend = _isValidEmail && !state.isSendLoading;
    final canVerify = _isValidCode &&
        !state.isVerifyLoading &&
        !isExpired &&
        !isVerified;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: SizedBox(
          height: 54,
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () { if (context.canPop()) context.pop(); },
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),

              const SizedBox(height: 16),

              const Text(
                '비밀번호 찾기',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67F2),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                '가입한 이메일로\n인증번호를 받아주세요.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.5,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                '이메일',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 8),

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
                        hintText: '가입한 이메일을 입력해주세요.',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                  ),
                  if (_hasSentCode) ...[
                    const SizedBox(width: 10),
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              if (state.sendError != null)
                Text(
                  state.sendError!,
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                )
              else if (isVerified)
                const Text(
                  '인증이 완료된 이메일이에요.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF4A67F2)),
                )
              else if (_hasSentCode)
                const Text(
                  '인증번호를 전송했어요.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                )
              else
                const Text(
                  '인증번호는 3분 동안 유효해요.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                ),

              if (_hasSentCode) ...[
                const SizedBox(height: 24),

                const Text(
                  '인증번호',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),

                if (isVerified)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF4A67F2), width: 1.2),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 20, color: Color(0xFF4A67F2)),
                        SizedBox(width: 10),
                        Text(
                          '이메일 인증이 완료되었어요.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
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
                            ref.read(findPasswordProvider.notifier).resetVerify();
                            setState(() {});
                          },
                          decoration: _inputDecoration(
                            hintText: '6자리 인증번호',
                            icon: Icons.verified_outlined,
                          ).copyWith(counterText: ''),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: canVerify ? _verifyCode : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A67F2),
                            disabledBackgroundColor: const Color(0xFFD7DEFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            state.isVerifyLoading ? '확인 중' : '확인',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                if (!isVerified)
                  Text(
                    isExpired
                        ? '인증 시간이 만료되었어요.'
                        : '남은 시간 ${_formatTime(_remainingSeconds)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isExpired
                          ? Colors.red
                          : const Color(0xFF4A67F2),
                    ),
                  ),

                if (state.verifyError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.verifyError!,
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
