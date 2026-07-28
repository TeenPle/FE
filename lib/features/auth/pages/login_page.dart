import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../models/login_blocked_reason.dart';
import '../provider/login_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberEmail = true;
  bool _keepLoggedIn = false;

  /// 회원가입 완료 안내 스낵바를 한 번만 띄우기 위한 플래그
  bool _hasShownSignupSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refreshSubmitState);
    _passwordController.addListener(_refreshSubmitState);
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final storage = ref.read(tokenStorageProvider);
    final rememberEmail = await storage.getRememberEmail();
    final savedEmail = rememberEmail ? await storage.getSavedEmail() : null;

    if (!mounted) return;

    setState(() {
      _rememberEmail = rememberEmail;
      if (savedEmail != null && savedEmail.trim().isNotEmpty) {
        _emailController.text = savedEmail.trim();
      }
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_refreshSubmitState);
    _passwordController.removeListener(_refreshSubmitState);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _refreshSubmitState() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// 회원가입 완료 후 로그인 페이지로 돌아온 경우 안내 문구 표시
    final signupStatus = GoRouterState.of(
      context,
    ).uri.queryParameters['signup'];

    if (!_hasShownSignupSuccessMessage && signupStatus == 'success') {
      _hasShownSignupSuccessMessage = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showAppSnackBar('회원가입 요청이 접수되었어요.');
      });
    }

    final resetStatus = GoRouterState.of(context).uri.queryParameters['reset'];

    if (!_hasShownSignupSuccessMessage && resetStatus == 'success') {
      _hasShownSignupSuccessMessage = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showAppSnackBar('비밀번호가 변경되었습니다. 새 비밀번호로 로그인해주세요.');
      });
    }
  }

  Future<void> _submit() async {
    if (ref.read(loginProvider).isLoading) return;

    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final storage = ref.read(tokenStorageProvider);
    await storage.saveRememberEmail(_rememberEmail);
    if (_rememberEmail && email.isNotEmpty) {
      await storage.saveSavedEmail(email);
    } else {
      await storage.clearSavedEmail();
    }

    await ref
        .read(loginProvider.notifier)
        .login(email: email, password: password, keepLoggedIn: _keepLoggedIn);

    final latestState = ref.read(loginProvider);

    if (!mounted) return;

    if (latestState.loginResponse != null) {
      if (latestState.loginResponse!.isAdmin) {
        context.go(AppRoutes.adminHome);
      } else {
        context.go(AppRoutes.school);
      }
      return;
    }

    if (latestState.blockedReason == LoginBlockedReason.rejected) {
      context.go(AppRoutes.schoolVerificationRejected);
      return;
    }

    // 탈퇴 유예 기간 중인 계정 → 복구 안내 화면으로 분기
    if (latestState.blockedReason == LoginBlockedReason.pendingDeletion) {
      context.go(AppRoutes.accountRecovery);
      return;
    }

    if (latestState.blockedReason != null) {
      context.go(AppRoutes.schoolVerificationWaiting);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loginState = ref.watch(loginProvider);

    final c = context.colors;
    final isSignupRequestComplete =
        GoRouterState.of(context).uri.queryParameters['signup'] == 'success';
    final signupNoticeBg = isDark
        ? const Color(0xFF1E2C46)
        : const Color(0xFFEFF3FF);
    final signupNoticeBorder = isDark
        ? const Color(0xFF2E4268)
        : const Color(0xFFD7DEFF);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: c.cardBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
            final keyboardShift = keyboardInset > 0
                ? -(keyboardInset * 0.48).clamp(96.0, 168.0)
                : 0.0;
            final minContentHeight = (constraints.maxHeight - 64).clamp(
              0.0,
              double.infinity,
            );

            return SingleChildScrollView(
              physics: keyboardInset > 0
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                24,
                32,
                24,
                keyboardInset > 0 ? keyboardInset + 32 : 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minContentHeight),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(0, keyboardShift, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          Center(
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: c.subtleBg,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'assets/images/Logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        'T',
                                        style: AppTextStyles.displayLarge
                                            .copyWith(color: Color(0xFF4A67F2)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: Text(
                              'TeenPle',
                              style: AppTextStyles.displayLarge.copyWith(
                                letterSpacing: -0.8,
                                color: c.textPrimary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Center(
                            child: Text(
                              '우리 학교와 동네를 잇는 학생 커뮤니티',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                height: 1.5,
                                color: c.textSecondary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          if (isSignupRequestComplete) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: signupNoticeBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: signupNoticeBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 20,
                                    color: Color(0xFF4A67F2),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '회원가입 요청이 완료되었어요',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                color: c.textPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '학교 인증 확인 후 서비스 이용이 가능해요. 보통 24시간 이내에 승인 또는 반려 결과를 알려드릴게요.',
                                          style: AppTextStyles.captionLarge
                                              .copyWith(
                                                height: 1.5,
                                                color: c.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: c.textPrimary,
                            ),
                            onChanged: (_) {
                              ref
                                  .read(loginProvider.notifier)
                                  .clearTransientState();
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: '이메일을 입력해주세요.',
                              hintStyle: AppTextStyles.captionLarge.copyWith(
                                color: c.textHint,
                              ),
                              filled: true,
                              fillColor: c.inputBg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                color: c.textMuted,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Color(0xFF4A67F2),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.password],
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: c.textPrimary,
                            ),
                            onSubmitted: (_) {
                              _submit();
                            },
                            onChanged: (_) {
                              ref
                                  .read(loginProvider.notifier)
                                  .clearTransientState();
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: '비밀번호를 입력해주세요.',
                              hintStyle: AppTextStyles.captionLarge.copyWith(
                                color: c.textHint,
                              ),
                              filled: true,
                              fillColor: c.inputBg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: c.textMuted,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: c.textMuted,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Color(0xFF4A67F2),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => setState(
                                        () => _rememberEmail = !_rememberEmail,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: Checkbox(
                                              value: _rememberEmail,
                                              onChanged: (value) => setState(
                                                () => _rememberEmail =
                                                    value ?? true,
                                              ),
                                              activeColor: const Color(
                                                0xFF4A67F2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              side: BorderSide(
                                                color: c.textTertiary,
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              '아이디 저장',
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.captionSmall
                                                  .copyWith(
                                                    color: c.textSecondary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => setState(
                                        () => _keepLoggedIn = !_keepLoggedIn,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: Checkbox(
                                              value: _keepLoggedIn,
                                              onChanged: (value) => setState(
                                                () => _keepLoggedIn =
                                                    value ?? false,
                                              ),
                                              activeColor: const Color(
                                                0xFF4A67F2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              side: BorderSide(
                                                color: c.textTertiary,
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              '로그인 상태 유지',
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.captionSmall
                                                  .copyWith(
                                                    color: c.textSecondary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.findEmail),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      '아이디 찾기',
                                      style: AppTextStyles.captionSmall
                                          .copyWith(color: c.textSecondary),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '|',
                                      style: AppTextStyles.captionSmall
                                          .copyWith(color: c.textTertiary),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.findPassword),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      '비밀번호 찾기',
                                      style: AppTextStyles.captionSmall
                                          .copyWith(color: c.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          if (loginState.errorMessage != null &&
                              loginState.errorMessage!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                loginState.errorMessage!,
                                style: AppTextStyles.captionSmall.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            ),

                          const SizedBox(height: 18),

                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: loginState.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A67F2),
                                disabledBackgroundColor: isDark
                                    ? const Color(0xFF2D3460)
                                    : const Color(0xFFBFC8FF),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: isDark
                                    ? Colors.white38
                                    : Colors.white70,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                loginState.isLoading ? '로그인 중...' : '로그인',
                                style: AppTextStyles.titleSmall,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '계정이 없으신가요?',
                                  style: AppTextStyles.captionLarge.copyWith(
                                    color: c.textTertiary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref.read(loginProvider.notifier).reset();
                                    context.push(AppRoutes.signupConsent);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    '회원가입',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: Color(0xFF4A67F2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
