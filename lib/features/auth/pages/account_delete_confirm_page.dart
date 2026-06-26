import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../provider/login_provider.dart';
import '../../profile/provider/profile_provider.dart';

/// 탈퇴 확인 페이지.
/// "회원탈퇴"를 직접 입력해야 탈퇴 버튼이 활성화되며, 확인 후 7일 유예 탈퇴 처리된다.
class AccountDeleteConfirmPage extends ConsumerStatefulWidget {
  const AccountDeleteConfirmPage({super.key});

  @override
  ConsumerState<AccountDeleteConfirmPage> createState() =>
      _AccountDeleteConfirmPageState();
}

class _AccountDeleteConfirmPageState
    extends ConsumerState<AccountDeleteConfirmPage> {
  final _controller = TextEditingController();

  // 사용자가 입력해야 하는 확인 문구
  static const _confirmText = '회원탈퇴';

  bool get _canDelete => _controller.text == _confirmText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref.read(profileProvider.notifier).deleteAccount();
    if (!mounted) return;

    if (success) {
      // 탈퇴 요청이 접수되면 사용자를 즉시 로그인 화면으로 보내고,
      // 서버 로그아웃 및 로컬 세션 정리는 이어서 완료한다.
      final logoutFuture = ref.read(loginProvider.notifier).logout();
      context.go(AppRoutes.login);
      showAppSnackBar('탈퇴 요청이 접수되었습니다.');
      await logoutFuture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profileState = ref.watch(profileProvider);
    final isLoading = profileState.isSaving;

    ref.listen(profileProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        showAppSnackBar(
          next.errorMessage!,
          backgroundColor: const Color(0xFFE05C7B),
        );
        ref.read(profileProvider.notifier).clearMessages();
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
          '회원 탈퇴',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WarningCard(c: c),
                  const SizedBox(height: 16),
                  _NoticeList(c: c),
                  const SizedBox(height: 16),
                  _ConfirmInputCard(
                    c: c,
                    controller: _controller,
                    confirmText: _confirmText,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_canDelete && !isLoading) ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE05C7B),
                        disabledBackgroundColor: c.subtleBg,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: c.textMuted,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isLoading ? '처리 중...' : '탈퇴하기',
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
                      onPressed: isLoading ? null : () => context.pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: c.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 상단 경고 카드 — 7일 유예 안내 포함
class _WarningCard extends StatelessWidget {
  final AppColors c;
  const _WarningCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234160).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE05C7B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 20,
                  color: Color(0xFFE05C7B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '정말 탈퇴하시겠어요?',
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '탈퇴 후 7일 이내에는 계정을 복구할 수 있어요.\n7일이 지나면 모든 개인정보가 영구적으로 삭제됩니다.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              height: 1.6,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmInputCard extends StatelessWidget {
  final AppColors c;
  final TextEditingController controller;
  final String confirmText;
  final VoidCallback onChanged;

  const _ConfirmInputCard({
    required this.c,
    required this.controller,
    required this.confirmText,
    required this.onChanged,
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
            '확인 문구 입력',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '탈퇴하려면 아래에 "$confirmText"를 정확히 입력해주세요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              height: 1.5,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: c.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: confirmText,
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
                  color: Color(0xFFE05C7B),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 탈퇴 유의사항 리스트
class _NoticeList extends StatelessWidget {
  final AppColors c;
  const _NoticeList({required this.c});

  static const _items = [
    '작성한 게시글과 댓글은 "탈퇴한 사용자"로 표시됩니다.',
    '7일 유예 기간 중에는 로그인 시 계정을 복구할 수 있어요.',
    '7일 후에는 이름, 이메일, 전화번호 등 모든 개인정보가 삭제됩니다.',
    '삭제된 데이터는 복구할 수 없으니 신중히 결정해주세요.',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            '탈퇴 전 꼭 확인해주세요',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? c.tintBg : const Color(0xFFEAF6FF),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Color(0xFF2B83F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        height: 1.55,
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
    );
  }
}
