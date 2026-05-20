import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../provider/login_provider.dart';

/// 탈퇴 유예 기간 중 로그인 시 표시되는 복구 안내 페이지.
/// 비밀번호를 직접 입력해야 복구 버튼이 활성화되어 의도치 않은 복구를 방지한다.
/// "탈퇴 유지"를 누르면 로그인 화면으로 돌아간다.
class AccountRecoveryPage extends ConsumerStatefulWidget {
  const AccountRecoveryPage({super.key});

  @override
  ConsumerState<AccountRecoveryPage> createState() =>
      _AccountRecoveryPageState();
}

class _AccountRecoveryPageState extends ConsumerState<AccountRecoveryPage> {
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canRestore => _passwordController.text.isNotEmpty;

  Future<void> _restore() async {
    // 입력한 비밀번호를 loginState의 attemptedPassword에 반영한 뒤 복구 요청
    ref
        .read(loginProvider.notifier)
        .updateAttemptedPassword(_passwordController.text);
    await ref.read(loginProvider.notifier).restoreAccount(keepLoggedIn: true);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final c = context.colors;

    // 복구 성공 시 홈으로 이동
    ref.listen(loginProvider, (_, next) {
      if (next.loginResponse != null) {
        showAppSnackBar('계정이 복구되었습니다.');
        if (next.loginResponse!.isAdmin) {
          context.go(AppRoutes.adminHome);
        } else {
          context.go(AppRoutes.school);
        }
      }
    });

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '계정 복구',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RecoveryHero(c: c),
                    const SizedBox(height: 16),
                    _InfoCard(c: c),
                    const SizedBox(height: 16),
                    _PasswordInputCard(
                      c: c,
                      controller: _passwordController,
                      obscure: _obscure,
                      onChanged: () => setState(() {}),
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_canRestore && !loginState.isLoading)
                            ? _restore
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B83F6),
                          disabledBackgroundColor: const Color(0xFFBBD6FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          loginState.isLoading ? '복구 중...' : '계정 복구하기',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: TextButton(
                        onPressed: loginState.isLoading
                            ? null
                            : () {
                                ref.read(loginProvider.notifier).reset();
                                context.go(AppRoutes.login);
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: c.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          '탈퇴 유지',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // 에러 메시지 (비밀번호 틀렸을 때 등)
                    if (loginState.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        loginState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 12,
                          color: const Color(0xFFE05C7B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordInputCard extends StatelessWidget {
  final AppColors c;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onChanged;
  final VoidCallback onToggleObscure;

  const _PasswordInputCard({
    required this.c,
    required this.controller,
    required this.obscure,
    required this.onChanged,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '비밀번호 확인',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '계정 복구를 위해 현재 비밀번호를 한 번 더 입력해주세요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              height: 1.5,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: (_) => onChanged(),
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: c.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '비밀번호 입력',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: c.textHint,
              ),
              filled: true,
              fillColor: c.subtleBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2B83F6),
                  width: 1.2,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 19,
                  color: c.iconSecondary,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 상단 히어로 카드 — 앱 테마(파란 그라디언트)에 맞춘 안내 영역
class _RecoveryHero extends StatelessWidget {
  final AppColors c;
  const _RecoveryHero({required this.c});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF182334), Color(0xFF132033)]
              : const [Color(0xFFF4FAFF), Color(0xFFEAF6FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? c.borderBlue : const Color(0xFFDCEEFF),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B83F6).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2B83F6).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restore_rounded,
              size: 24,
              color: Color(0xFF2B83F6),
            ),
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '탈퇴 대기 중인\n',
                  style: TextStyle(color: c.textPrimary),
                ),
                const TextSpan(
                  text: '계정',
                  style: TextStyle(color: Color(0xFF2B83F6)),
                ),
                TextSpan(
                  text: '이에요',
                  style: TextStyle(color: c.textPrimary),
                ),
              ],
            ),
            style: AppTextStyles.displaySmall.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.32,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '7일 이내에 복구할 수 있어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              height: 1.55,
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// 안내 사항 카드
class _InfoCard extends StatelessWidget {
  final AppColors c;
  const _InfoCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            c: c,
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF2B83F6),
            text: '복구하면 모든 기록이 그대로 유지돼요.',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            c: c,
            icon: Icons.timer_rounded,
            iconColor: const Color(0xFFD97706),
            text: '유예 기간이 지나면 영구 삭제되어 복구할 수 없어요.',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            c: c,
            icon: Icons.lock_rounded,
            iconColor: c.textMuted,
            text: '탈퇴를 유지해도 기존 게시글은 남아있어요.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final AppColors c;
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoRow({
    required this.c,
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              height: 1.5,
              color: c.textBody,
            ),
          ),
        ),
      ],
    );
  }
}
