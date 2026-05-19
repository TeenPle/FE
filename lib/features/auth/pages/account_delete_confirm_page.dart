import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
      // 탈퇴 요청 성공 → 세션 초기화 후 로그인 화면으로 이동
      await ref.read(loginProvider.notifier).logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isLoading = ref.watch(profileProvider).isLoading;

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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 경고 헤더 카드
                  _WarningCard(c: c),
                  const SizedBox(height: 24),

                  // 탈퇴 시 유의 사항
                  _NoticeList(c: c),
                  const SizedBox(height: 28),

                  // 확인 문구 입력 안내
                  Text(
                    '탈퇴하려면 아래에 "$_confirmText"를 입력해주세요.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      color: c.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: _confirmText,
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
                          color: Color(0xFFE05C7B),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 탈퇴 버튼: 확인 문구 입력 전까지 비활성화
                  SizedBox(
                    width: double.infinity,
                    height: 52,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 취소 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => context.pop(),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCDD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE05C7B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '정말 탈퇴하시겠어요?',
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB03358),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '탈퇴 후 7일 이내에는 계정을 복구할 수 있어요.\n7일이 지나면 모든 개인정보가 영구적으로 삭제됩니다.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF8C3252),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.subtleBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '탈퇴 전 꼭 확인해주세요',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.textMuted,
                        shape: BoxShape.circle,
                      ),
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
