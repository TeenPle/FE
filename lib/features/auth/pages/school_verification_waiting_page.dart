import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../models/login_blocked_reason.dart';
import '../provider/login_provider.dart';

/// 학교 인증 상태 때문에 메인 페이지로 못 가는 경우 보여줄 페이지
class SchoolVerificationWaitingPage extends ConsumerWidget {
  const SchoolVerificationWaitingPage({super.key});

  /// 상단 배지 문구
  String _statusLabel() {
    return '학교 인증 확인 중';
  }

  /// 상단 아이콘
  IconData _statusIcon() {
    return Icons.schedule_rounded;
  }

  /// 하단 안내 문구
  String _helperText() {
    return '학교 인증은 관리자 확인 후 처리돼요.\n승인까지 시간이 조금 걸릴 수 있어요.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginProvider);

    /// 상태가 없으면 기본값은 pending으로 처리
    final blockedReason =
        loginState.blockedReason ?? LoginBlockedReason.pending;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              /// 로그인 상태 초기화 후 로그인 화면으로 복귀
              ref.read(loginProvider.notifier).reset();
              context.go(AppRoutes.landing);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A67F2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              /// 상태 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _statusIcon(),
                  size: 30,
                  color: const Color(0xFF4A67F2),
                ),
              ),

              const SizedBox(height: 24),

              /// 상태 배지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A67F2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// 제목
              Text(
                blockedReason.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.22,
                  letterSpacing: -0.6,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 12),

              /// 설명
              Text(
                blockedReason.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF555555),
                ),
              ),

              const SizedBox(height: 24),

              /// 안내 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE3E7EF),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF7A7A7A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _helperText(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF666666),
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
    );
  }
}