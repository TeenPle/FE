import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../provider/signup_form_provider.dart';

/// 회원가입 6단계 비밀번호 설정 페이지
class SignupPasswordPage extends ConsumerStatefulWidget {
  const SignupPasswordPage({super.key});

  @override
  ConsumerState<SignupPasswordPage> createState() => _SignupPasswordPageState();
}

class _SignupPasswordPageState extends ConsumerState<SignupPasswordPage> {
  /// 비밀번호 입력 컨트롤러
  late final TextEditingController _passwordController;

  /// 비밀번호 재입력 컨트롤러
  late final TextEditingController _passwordConfirmController;

  /// 비밀번호 표시 여부
  bool _obscurePassword = true;

  /// 비밀번호 재입력 표시 여부
  bool _obscurePasswordConfirm = true;

  @override
  void initState() {
    super.initState();

    /// 기존 입력값이 있으면 복원
    final formState = ref.read(signupFormProvider);

    _passwordController = TextEditingController(text: formState.password);
    _passwordConfirmController = TextEditingController(
      text: formState.passwordConfirm,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  /// 비밀번호 유효성 검사
  ///
  /// 백엔드 규칙과 동일하게 맞춤
  /// - 8~20자
  /// - 영문 1개 이상
  /// - 숫자 1개 이상
  /// - 특수문자 1개 이상
  /// - 허용 특수문자: @$!%*#?&
  bool _isValidPassword(String value) {
    final regex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,20}$',
    );
    return regex.hasMatch(value);
  }

  /// 공통 입력창 스타일
  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFFB0B0B0),
        fontSize: 12,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE3E7EF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE3E7EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF4A67F2),
          width: 1.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 회원가입 전체 상태
    final signupFormState = ref.watch(signupFormProvider);

    /// 현재 입력값
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    /// 비밀번호 규칙 통과 여부
    final isPasswordValid = _isValidPassword(password);

    /// 비밀번호 재입력 일치 여부
    final isPasswordConfirmValid =
        passwordConfirm.isNotEmpty && password == passwordConfirm;

    /// 다음 버튼 활성화 조건
    final canProceed = isPasswordValid && isPasswordConfirmValid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),

      /// 하단 고정 버튼
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: canProceed
                ? () {
              /// 입력값 저장
              ref.read(signupFormProvider.notifier).updatePassword(
                password,
              );
              ref
                  .read(signupFormProvider.notifier)
                  .updatePasswordConfirm(passwordConfirm);

              /// 다음 단계인 전화번호 입력 페이지로 이동
              context.push(AppRoutes.signupPhone);
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
            child: const Text(
              '다음',
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                splashRadius: 22,
              ),

              const SizedBox(height: 8),

              /// 단계 표시
              const Text(
                '6/8',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),

              const SizedBox(height: 14),

              /// 페이지 성격 안내
              const Text(
                '보안 설정',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67F2),
                ),
              ),

              const SizedBox(height: 8),

              /// 제목
              const Text(
                '거의 다 왔어요!\n비밀번호를 설정해주세요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.22,
                  letterSpacing: -0.6,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 10),

              /// 보조 문구
              const Text(
                'TeenPle에서 사용할 비밀번호를 입력해주세요.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF555555),
                ),
              ),

              const SizedBox(height: 28),

              /// 가입 이메일 라벨
              const Text(
                '가입 이메일',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 8),

              /// 이메일 표시 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE3E7EF),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: Color(0xFF7A7A7A),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        signupFormState.email.isEmpty
                            ? '이메일 정보가 없습니다.'
                            : signupFormState.email,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: signupFormState.email.isEmpty
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: signupFormState.email.isEmpty
                              ? const Color(0xFF9A9A9A)
                              : const Color(0xFF222222),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// 비밀번호 라벨
              const Text(
                '비밀번호',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 8),

              /// 비밀번호 입력창
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (value) {
                  /// provider에 즉시 반영
                  ref.read(signupFormProvider.notifier).updatePassword(value);
                  setState(() {});
                },
                decoration: _inputDecoration(
                  hintText: '비밀번호를 입력해주세요',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF7A7A7A),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// 비밀번호 안내/에러 메시지
              if (password.isEmpty)
                const Text(
                  '영문, 숫자, 특수문자(@\$!%*#?&)를 포함해 8~20자로 입력해주세요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                  ),
                )
              else if (!isPasswordValid)
                const Text(
                  '비밀번호는 영문, 숫자, 특수문자(@\$!%*#?&)를 포함한 8~20자여야 해요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                )
              else
                const Text(
                  '사용 가능한 비밀번호 형식이에요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4A67F2),
                  ),
                ),

              const SizedBox(height: 20),

              /// 비밀번호 확인 라벨
              const Text(
                '비밀번호 확인',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 8),

              /// 비밀번호 재입력 입력창
              TextField(
                controller: _passwordConfirmController,
                obscureText: _obscurePasswordConfirm,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (value) {
                  /// provider에 즉시 반영
                  ref
                      .read(signupFormProvider.notifier)
                      .updatePasswordConfirm(value);
                  setState(() {});
                },
                decoration: _inputDecoration(
                  hintText: '비밀번호를 다시 입력해주세요',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF7A7A7A),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePasswordConfirm = !_obscurePasswordConfirm;
                      });
                    },
                    icon: Icon(
                      _obscurePasswordConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// 비밀번호 재입력 안내/에러 메시지
              if (passwordConfirm.isNotEmpty && password != passwordConfirm)
                const Text(
                  '비밀번호가 일치하지 않아요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                )
              else if (passwordConfirm.isNotEmpty &&
                  password == passwordConfirm &&
                  isPasswordValid)
                const Text(
                  '비밀번호가 일치해요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4A67F2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}