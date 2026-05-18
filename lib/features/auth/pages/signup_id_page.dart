import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_bottom_action_area.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../provider/signup_email_check_provider.dart';
import '../provider/signup_form_provider.dart';

/// 회원가입 4단계 - 이메일 입력 페이지
///
/// 파일명은 signup_id_page.dart를 유지해도 되지만
/// 실제 역할은 이메일 입력 페이지로 사용
class SignupIdPage extends ConsumerStatefulWidget {
  const SignupIdPage({super.key});

  @override
  ConsumerState<SignupIdPage> createState() => _SignupIdPageState();
}

class _SignupIdPageState extends ConsumerState<SignupIdPage> {
  /// 이메일 입력 컨트롤러
  late final TextEditingController _emailController;

  /// 디바운스 타이머
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    /// 기존에 입력한 이메일이 있으면 복원
    final currentEmail = ref.read(signupFormProvider).email;
    _emailController = TextEditingController(text: currentEmail);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  /// 이메일 형식 검사
  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return regex.hasMatch(value);
  }

  /// 이메일 입력 시 호출
  void _onChanged(String value) {
    final trimmed = value.trim();

    /// 회원가입 전체 상태에 이메일 저장
    ref.read(signupFormProvider.notifier).updateEmail(value);

    /// 이메일이 바뀌면 기존 인증 토큰 제거
    ref.read(signupFormProvider.notifier).updateVerificationToken('');

    /// 기존 중복 확인 타이머 취소
    _debounce?.cancel();

    /// 입력이 바뀌면 이전 확인 결과는 무효화
    ref.read(signupEmailCheckProvider.notifier).reset();

    /// 화면 즉시 갱신
    setState(() {});

    /// 이메일 형식이 아니면 API 호출 안 함
    if (!_isValidEmail(trimmed)) {
      return;
    }

    /// 500ms 뒤 중복 확인 API 호출
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(signupEmailCheckProvider.notifier).checkEmail(trimmed);
    });
  }

  /// 공통 입력창 스타일
  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    Widget? prefixIcon,
  }) {
    final c = context.colors;
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.captionLarge.copyWith(color: c.textHint),
      filled: true,
      fillColor: c.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      prefixIcon: prefixIcon,
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
    final email = _emailController.text.trim();

    /// 이메일 중복 확인 상태
    final emailCheckState = ref.watch(signupEmailCheckProvider);

    /// 이메일 형식 유효 여부
    final isValidEmail = _isValidEmail(email);

    /// 현재 입력값과 마지막 확인값이 같은지 확인
    final isSameAsChecked = emailCheckState.checkedEmail == email;

    /// 다음 버튼 활성화 조건
    final canProceed =
        isValidEmail &&
        emailCheckState.isAvailable == true &&
        isSameAsChecked &&
        !emailCheckState.isLoading;

    return AuthStepLayout(
      bottom: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: canProceed
              ? () {
                  /// 현재 이메일을 최종 저장
                  ref.read(signupFormProvider.notifier).updateEmail(email);

                  /// 다음 단계인 이메일 인증 페이지로 이동
                  context.push(AppRoutes.signupEmailVerify);
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
          child: Text('다음', style: AppTextStyles.titleSmall),
        ),
      ),
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
            '4/8',
            style: AppTextStyles.labelSmall.copyWith(
              color: context.colors.textTertiary,
            ),
          ),

          SizedBox(height: 14),

          /// 페이지 성격 안내
          Text(
            '계정 정보',
            style: AppTextStyles.labelSmall.copyWith(color: Color(0xFF4A67F2)),
          ),

          SizedBox(height: 8),

          /// 제목
          Text(
            '이메일을 입력해주세요',
            style: AppTextStyles.displayLarge.copyWith(
              height: 1.22,
              letterSpacing: -0.6,
              color: context.colors.textPrimary,
            ),
          ),

          SizedBox(height: 10),

          /// 보조 문구
          Text(
            '가입 후 TeenPle 로그인과 이메일 인증에 사용할 주소예요.',
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.5,
              color: context.colors.textBody,
            ),
          ),

          SizedBox(height: 28),

          /// 이메일 라벨
          Text(
            '이메일',
            style: AppTextStyles.labelSmall.copyWith(
              color: context.colors.textMuted,
            ),
          ),

          SizedBox(height: 8),

          /// 이메일 입력창
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            onChanged: _onChanged,
            decoration: _inputDecoration(
              context,
              hintText: '이메일을 입력해주세요',
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                color: context.colors.iconSecondary,
              ),
            ),
          ),

          SizedBox(height: 10),

          /// 상태 메시지
          Builder(
            builder: (context) {
              if (email.isEmpty) {
                return Text(
                  '로그인과 본인 확인에 사용할 이메일이에요.',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: context.colors.textMuted,
                  ),
                );
              }

              if (!isValidEmail) {
                return Text(
                  '올바른 이메일 형식으로 입력해주세요.',
                  style: AppTextStyles.captionSmall.copyWith(color: Colors.red),
                );
              }

              if (emailCheckState.isLoading) {
                return Text(
                  '이메일 사용 가능 여부를 확인하고 있어요.',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: Color(0xFF4A67F2),
                  ),
                );
              }

              if (emailCheckState.errorMessage != null && isSameAsChecked) {
                return Text(
                  emailCheckState.errorMessage!,
                  style: AppTextStyles.captionSmall.copyWith(color: Colors.red),
                );
              }

              if (emailCheckState.isAvailable == false && isSameAsChecked) {
                return Text(
                  '이미 사용 중인 이메일이에요.',
                  style: AppTextStyles.captionSmall.copyWith(color: Colors.red),
                );
              }

              if (emailCheckState.isAvailable == true && isSameAsChecked) {
                return Text(
                  '사용 가능한 이메일이에요.',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: Color(0xFF4A67F2),
                  ),
                );
              }

              return Text(
                '로그인과 본인 확인에 사용할 이메일이에요.',
                style: AppTextStyles.captionSmall.copyWith(
                  color: context.colors.textMuted,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
