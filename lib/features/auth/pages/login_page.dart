import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
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
  bool _keepLoggedIn = false;

  /// 회원가입 완료 안내 스낵바를 한 번만 띄우기 위한 플래그
  bool _hasShownSignupSuccessMessage = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

        showAppSnackBar('회원가입을 완료했습니다.');
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

  void _showComingSoonSnackBar(String label) {
    showAppSnackBar('$label 기능은 준비 중입니다.');
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

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

    if (latestState.blockedReason != null) {
      context.go(AppRoutes.schoolVerificationWaiting);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final canLogin =
        email.isNotEmpty && password.isNotEmpty && !loginState.isLoading;

    final c = context.colors;

    return Scaffold(
      backgroundColor: c.cardBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                // 뷰포트 높이를 최소 높이로 설정 → 키보드가 없을 때는 Center가 세로 중앙에 배치되고,
                // 키보드가 올라와 높이가 줄어들면 자연스럽게 스크롤이 동작한다.
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 16),

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
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF4A67F2),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        Center(
                          child: Text(
                            'TeenPle',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: c.textPrimary,
                            ),
                          ),
                        ),

                        SizedBox(height: 8),

                        Center(
                          child: Text(
                            '우리 학교와 동네를 잇는 학생 커뮤니티',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: c.textSecondary,
                            ),
                          ),
                        ),

                        SizedBox(height: 36),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          style: TextStyle(fontSize: 13, color: c.textPrimary),
                          onChanged: (_) {
                            ref.read(loginProvider.notifier).clearTransientState();
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: '이메일을 입력해주세요.',
                            hintStyle: TextStyle(fontSize: 12, color: c.textHint),
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

                        SizedBox(height: 12),

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(fontSize: 13, color: c.textPrimary),
                          onSubmitted: (_) {
                            if (canLogin) _submit();
                          },
                          onChanged: (_) {
                            ref.read(loginProvider.notifier).clearTransientState();
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: '비밀번호를 입력해주세요.',
                            hintStyle: TextStyle(fontSize: 12, color: c.textHint),
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

                        SizedBox(height: 14),

                        Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () =>
                                  setState(() => _keepLoggedIn = !_keepLoggedIn),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _keepLoggedIn,
                                      onChanged: (value) => setState(
                                        () => _keepLoggedIn = value ?? false,
                                      ),
                                      activeColor: const Color(0xFF4A67F2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: BorderSide(
                                        color: c.textTertiary,
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '로그인 상태 유지',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push(AppRoutes.findEmail),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                '아이디 찾기',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '|',
                                style: TextStyle(fontSize: 11, color: c.textTertiary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(AppRoutes.findPassword),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                '비밀번호 찾기',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),

                        if (loginState.errorMessage != null &&
                            loginState.errorMessage!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              loginState.errorMessage!,
                              style: TextStyle(fontSize: 11, color: Colors.red),
                            ),
                          ),

                        SizedBox(height: 18),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: canLogin ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A67F2),
                              disabledBackgroundColor: const Color(0xFFBFC8FF),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white70,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              loginState.isLoading ? '로그인 중...' : '로그인',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 18),

                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '계정이 없으신가요?',
                                style: TextStyle(fontSize: 12, color: c.textTertiary),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.read(loginProvider.notifier).reset();
                                  context.push(AppRoutes.signupConsent);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '회원가입',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
            );
          },
        ),
      ),
    );
  }
}
