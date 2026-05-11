import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/signup_email_send_provider.dart';
import '../provider/signup_email_verify_provider.dart';
import '../provider/signup_form_provider.dart';

/// 회원가입 5단계 - 이메일 인증 페이지
class SignupEmailVerifyPage extends ConsumerStatefulWidget {
  const SignupEmailVerifyPage({super.key});

  @override
  ConsumerState<SignupEmailVerifyPage> createState() =>
      _SignupEmailVerifyPageState();
}

class _SignupEmailVerifyPageState
    extends ConsumerState<SignupEmailVerifyPage> {
  /// 인증번호 입력 컨트롤러
  final TextEditingController _codeController = TextEditingController();

  /// 인증번호를 한 번이라도 전송했는지 여부
  bool _hasSentCode = false;

  /// 인증번호 만료까지 남은 시간(초)
  int _remainingSeconds = 300;

  /// 카운트다운 타이머
  Timer? _countdownTimer;

  @override
  void dispose() {
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 인증번호가 6자리 숫자인지 검사
  bool _isValidCode(String value) {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(value.trim());
  }

  /// mm:ss 형태로 변환
  String _formatRemainingTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 5분 카운트다운 시작
  void _startCountdown() {
    _countdownTimer?.cancel();

    setState(() {
      _remainingSeconds = 300;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  /// 인증번호 전송 처리
  Future<void> _sendVerificationCode(String email) async {
    /// 이전 인증 토큰 제거
    ref.read(signupFormProvider.notifier).updateVerificationToken('');

    await ref.read(signupEmailSendProvider.notifier).sendCode(email);

    final latestSendState = ref.read(signupEmailSendProvider);

    /// 전송 성공 시 인증번호 입력 영역 노출
    if (latestSendState.isSuccess) {
      /// 이전 인증 상태 초기화
      ref.read(signupEmailVerifyProvider.notifier).reset();

      setState(() {
        _hasSentCode = true;
      });

      /// 5분 타이머 시작
      _startCountdown();
    }
  }

  /// 인증번호 재전송 처리
  Future<void> _resendVerificationCode(String email) async {
    /// 이전 인증 토큰 제거
    ref.read(signupFormProvider.notifier).updateVerificationToken('');

    /// 재전송 시 기존 인증 결과 초기화
    ref.read(signupEmailVerifyProvider.notifier).reset();

    /// 입력창 초기화
    _codeController.clear();

    setState(() {});

    await ref.read(signupEmailSendProvider.notifier).sendCode(email);

    final latestSendState = ref.read(signupEmailSendProvider);

    /// 재전송 성공 시 5분 타이머 재시작
    if (latestSendState.isSuccess) {
      setState(() {
        _hasSentCode = true;
      });
      _startCountdown();
    }
  }

  /// 공통 입력창 스타일
  InputDecoration _inputDecoration(BuildContext context, {
    required String hintText,
    Widget? prefixIcon,
  }) {
    final c = context.colors;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: c.textHint,
        fontSize: 12,
      ),
      filled: true,
      fillColor: c.inputBg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.colors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.colors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Color(0xFF4A67F2),
          width: 1.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 회원가입 상태에서 이메일 읽기
    final signupFormState = ref.watch(signupFormProvider);
    final email = signupFormState.email.trim();

    /// 인증번호 전송 상태
    final sendState = ref.watch(signupEmailSendProvider);

    /// 인증번호 확인 상태
    final verifyState = ref.watch(signupEmailVerifyProvider);

    /// 이메일이 존재하는지 여부
    final hasEmail = email.isNotEmpty;

    /// 인증 성공 여부
    ///
    /// verifyState.isSuccess는 일시적인 상태라
    /// verificationToken 존재 여부로 최종 판단
    final isVerified = signupFormState.verificationToken.trim().isNotEmpty;

    /// 인증 섹션 노출 여부
    final showVerificationSection = _hasSentCode || isVerified;

    /// 타이머가 끝났는지 여부
    final isExpired = showVerificationSection && _remainingSeconds == 0 && !isVerified;

    /// 확인 버튼 활성화 여부
    final canVerify =
        _isValidCode(_codeController.text) &&
            !verifyState.isLoading &&
            hasEmail &&
            !isExpired &&
            !isVerified;

    /// 하단 버튼 활성화 여부
    /// - 인증 완료 상태면 항상 다음 가능
    /// - 아직 전송 전이면 이메일이 있을 때만 인증번호 받기 가능
    final canPressBottomButton = isVerified
        ? true
        : (!_hasSentCode ? (hasEmail && !sendState.isLoading) : false);

    /// 하단 버튼 텍스트
    final bottomButtonText = isVerified
        ? '다음'
        : (sendState.isLoading ? '전송 중...' : '인증번호 받기');

    return Scaffold(
      backgroundColor: context.colors.pageBg,

      /// 하단 고정 버튼
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: canPressBottomButton
                ? () async {
              /// 인증 완료 상태면 다음 단계로 이동
              if (isVerified) {
                context.push(AppRoutes.signupPassword);
                return;
              }

              /// 아직 인증번호를 보내지 않은 상태라면 전송 수행
              if (!_hasSentCode) {
                await _sendVerificationCode(email);
                return;
              }
            }
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
              bottomButtonText,
              style: TextStyle(
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
              /// 상단 뒤로가기 버튼
              IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                icon: Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                splashRadius: 22,
              ),

              SizedBox(height: 8),

              /// 단계 표시
              Text(
                '5/8',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textTertiary,
                ),
              ),

              SizedBox(height: 14),

              /// 페이지 성격 안내
              Text(
                '이메일 인증',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67F2),
                ),
              ),

              SizedBox(height: 8),

              /// 제목
              Text(
                '이메일을 인증해주세요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.22,
                  letterSpacing: -0.6,
                  color: context.colors.textPrimary,
                ),
              ),

              SizedBox(height: 10),

              /// 설명
              Text(
                isVerified
                    ? '이메일 인증이 완료되었어요.'
                    : (_hasSentCode
                    ? '받은 인증번호를 입력하면 다음 단계로 이동할 수 있어요.'
                    : '입력한 이메일로 인증번호를 보내드릴게요.'),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: context.colors.textBody,
                ),
              ),

              SizedBox(height: 28),

              /// 이메일 라벨
              Text(
                '인증할 이메일',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textMuted,
                ),
              ),

              SizedBox(height: 8),

              /// 이메일 표시 박스
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
                    color: context.colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: context.colors.iconSecondary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasEmail ? email : '이메일 정보가 없습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          hasEmail ? FontWeight.w600 : FontWeight.w400,
                          color: hasEmail
                              ? context.colors.textPrimary
                              : context.colors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              /// 전송 안내/에러 메시지
              if (sendState.errorMessage != null)
                Text(
                  sendState.errorMessage!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                )
              else if (isVerified)
                Text(
                  '인증이 완료된 이메일이에요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4A67F2),
                  ),
                )
              else if (!_hasSentCode)
                  Text(
                    '인증번호는 5분 동안 유효해요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.textMuted,
                    ),
                  )
                else
                  Text(
                    '인증번호를 전송했어요. 아래에서 확인을 완료해주세요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.textMuted,
                    ),
                  ),

              /// 인증번호를 한 번이라도 전송했거나 이미 인증 완료된 경우 노출
              if (showVerificationSection) ...[
                SizedBox(height: 28),

                /// 인증번호 라벨
                Text(
                  '인증번호',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textMuted,
                  ),
                ),

                SizedBox(height: 8),

                /// 이미 인증 완료된 경우 완료 상태 표시
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
                        Expanded(
                          child: Text(
                            '이메일 인증이 완료되었어요.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 인증번호 입력창
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onChanged: (_) {
                            /// 인증번호가 바뀌면 이전 인증 결과 초기화
                            ref.read(signupEmailVerifyProvider.notifier).reset();
                            setState(() {});
                          },
                          decoration: _inputDecoration(context,
                            hintText: '6자리 인증번호를 입력해주세요',
                            prefixIcon: Icon(
                              Icons.verified_outlined,
                              color: context.colors.iconSecondary,
                            ),
                          ).copyWith(
                            counterText: '',
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      /// 인증번호 확인 버튼
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: canVerify
                              ? () async {
                            await ref
                                .read(signupEmailVerifyProvider.notifier)
                                .verify(
                              email: email,
                              code: _codeController.text.trim(),
                            );

                            final latestVerifyState =
                            ref.read(signupEmailVerifyProvider);

                            /// 인증 성공 시 verificationToken 저장
                            if (latestVerifyState.isSuccess) {
                              ref
                                  .read(signupFormProvider.notifier)
                                  .updateVerificationToken(
                                latestVerifyState.verificationToken,
                              );

                              /// 인증 완료 시 타이머 종료
                              _countdownTimer?.cancel();
                            }

                            setState(() {});
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A67F2),
                            disabledBackgroundColor: const Color(0xFFD7DEFF),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            verifyState.isLoading ? '확인 중' : '확인',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 8),

                /// 타이머 / 재전송 영역
                if (!isVerified)
                  Row(
                    children: [
                      Text(
                        isExpired
                            ? '인증 시간이 만료되었어요.'
                            : '남은 시간 ${_formatRemainingTime(_remainingSeconds)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isExpired
                              ? Colors.red
                              : const Color(0xFF4A67F2),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: sendState.isLoading
                            ? null
                            : () async {
                          await _resendVerificationCode(email);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '인증번호 재전송',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A67F2),
                          ),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 8),

                /// 인증 상태 메시지
                if (!isVerified && verifyState.errorMessage != null)
                  Text(
                    verifyState.errorMessage!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  )
                else if (isVerified)
                  Text(
                    '아래 다음 버튼을 눌러 비밀번호 설정으로 이동해주세요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A67F2),
                    ),
                  )
                else if (_codeController.text.isNotEmpty &&
                      !_isValidCode(_codeController.text))
                    Text(
                      '인증번호는 6자리 숫자로 입력해주세요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    )
                  else if (isExpired)
                      Text(
                        '인증번호를 다시 전송한 뒤 새 번호로 인증해주세요.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
