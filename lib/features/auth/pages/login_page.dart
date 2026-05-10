import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
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
    final signupStatus =
    GoRouterState.of(context).uri.queryParameters['signup'];

    if (!_hasShownSignupSuccessMessage && signupStatus == 'success') {
      _hasShownSignupSuccessMessage = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('회원가입을 완료했습니다.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
      });
    }

    final resetStatus =
        GoRouterState.of(context).uri.queryParameters['reset'];

    if (!_hasShownSignupSuccessMessage && resetStatus == 'success') {
      _hasShownSignupSuccessMessage = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('비밀번호가 변경되었습니다. 새 비밀번호로 로그인해주세요.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
      });
    }
  }

  void _showComingSoonSnackBar(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label 기능은 준비 중입니다.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await ref.read(loginProvider.notifier).login(
      email: email,
      password: password,
      keepLoggedIn: _keepLoggedIn,
    );

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                        color: const Color(0xFFF5F8FF),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/Logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
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

                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'TeenPle',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Center(
                    child: Text(
                      '우리 학교와 동네를 잇는 학생 커뮤니티',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    onChanged: (_) {
                      ref.read(loginProvider.notifier).clearTransientState();
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '이메일을 입력해주세요.',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB3B3B3),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFF7A7A7A),
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
                        borderSide: const BorderSide(
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
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (canLogin) {
                        _submit();
                      }
                    },
                    onChanged: (_) {
                      ref.read(loginProvider.notifier).clearTransientState();
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력해주세요.',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB3B3B3),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                          color: const Color(0xFF7A7A7A),
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
                        borderSide: const BorderSide(
                          color: Color(0xFF4A67F2),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _keepLoggedIn = !_keepLoggedIn;
                          });
                        },
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _keepLoggedIn,
                                onChanged: (value) {
                                  setState(() {
                                    _keepLoggedIn = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF4A67F2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFB8BEC8),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '로그인 상태 유지',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          context.push(AppRoutes.findEmail);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '아이디 찾기',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '|',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push(AppRoutes.findPassword);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),

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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '계정이 없으신가요?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
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
                          child: const Text(
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
      ),
    );
  }
}