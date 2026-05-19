import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
    ref.read(loginProvider.notifier).updateAttemptedPassword(
          _passwordController.text,
        );
    await ref.read(loginProvider.notifier).restoreAccount(keepLoggedIn: true);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final c = context.colors;

    // 복구 성공 시 홈으로 이동
    ref.listen(loginProvider, (_, next) {
      if (next.loginResponse != null) {
        if (next.loginResponse!.isAdmin) {
          context.go(AppRoutes.adminHome);
        } else {
          context.go(AppRoutes.school);
        }
      }
    });

    return Scaffold(
      backgroundColor: c.pageBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 히어로 카드
                    _RecoveryHero(c: c),
                    const SizedBox(height: 28),

                    // 안내 카드
                    _InfoCard(c: c),
                    const SizedBox(height: 28),

                    // 비밀번호 입력
                    Text(
                      '복구하려면 비밀번호를 입력해주세요.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        color: c.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '비밀번호 입력',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          color: c.textHint,
                        ),
                        filled: true,
                        fillColor: c.cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                          borderSide: const BorderSide(
                            color: Color(0xFF2B83F6),
                            width: 1.2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: c.iconSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 복구하기 버튼 — 비밀번호 입력 전 비활성화
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            (_canRestore && !loginState.isLoading)
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
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 탈퇴 유지 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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

// 상단 히어로 카드 — 앱 테마(파란 그라디언트)에 맞춘 안내 영역
class _RecoveryHero extends StatelessWidget {
  final AppColors c;
  const _RecoveryHero({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4FAFF), Color(0xFFEAF6FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCEEFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF2B83F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restore_rounded,
              size: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
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
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '7일 이내에 복구할 수 있어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
              fontSize: 13,
              height: 1.5,
              color: c.textBody,
            ),
          ),
        ),
      ],
    );
  }
}
