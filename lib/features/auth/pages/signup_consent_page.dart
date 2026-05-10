import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// 회원가입 시작 전 필수 동의 페이지
///
/// 법적으로 개인정보 수집 전 사전 동의가 필요합니다.
/// • 이용약관 (필수)
/// • 개인정보 수집·이용 동의 (필수)
/// • 만 14세 이상 확인 (필수, 정보통신망법 제31조)
class SignupConsentPage extends StatefulWidget {
  const SignupConsentPage({super.key});

  @override
  State<SignupConsentPage> createState() => _SignupConsentPageState();
}

class _SignupConsentPageState extends State<SignupConsentPage> {
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeAge = false;

  bool get _allAgreed => _agreeTerms && _agreePrivacy && _agreeAge;

  void _toggleAll(bool? value) {
    final checked = value ?? false;
    setState(() {
      _agreeTerms = checked;
      _agreePrivacy = checked;
      _agreeAge = checked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _allAgreed
                ? () => context.push(AppRoutes.signupSchool)
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
              '동의하고 계속하기',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기
              IconButton(
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                splashRadius: 22,
              ),

              const SizedBox(height: 24),

              const Text(
                '서비스 이용에\n동의해주세요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.6,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'TeenPle는 만 15세 이상 고등학교 재학생을 위한 서비스입니다.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF555555),
                ),
              ),

              const SizedBox(height: 32),

              // 전체 동의
              _AllAgreeCard(
                checked: _allAgreed,
                onChanged: _toggleAll,
              ),

              const SizedBox(height: 12),

              // 개별 항목
              _ConsentItem(
                checked: _agreeTerms,
                label: '[필수] 이용약관',
                onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                onViewTap: () => context.push(AppRoutes.terms),
              ),

              const SizedBox(height: 8),

              _ConsentItem(
                checked: _agreePrivacy,
                label: '[필수] 개인정보 수집·이용 동의',
                onChanged: (v) => setState(() => _agreePrivacy = v ?? false),
                onViewTap: () => context.push(AppRoutes.privacyPolicy),
              ),

              const SizedBox(height: 8),

              _AgeConsentItem(
                checked: _agreeAge,
                onChanged: (v) => setState(() => _agreeAge = v ?? false),
              ),

              const SizedBox(height: 24),

              const _PrivacyNote(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 전체 동의 카드 ───────────────────────────────────────

class _AllAgreeCard extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool?> onChanged;

  const _AllAgreeCard({required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: checked ? const Color(0xFFF2F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: checked ? const Color(0xFF4A67F2) : const Color(0xFFE3E7EF),
            width: checked ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          children: [
            _CheckCircle(checked: checked),
            const SizedBox(width: 12),
            const Text(
              '전체 동의',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 일반 동의 항목 ───────────────────────────────────────

class _ConsentItem extends StatelessWidget {
  final bool checked;
  final String label;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onViewTap;

  const _ConsentItem({
    required this.checked,
    required this.label,
    required this.onChanged,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E7EF)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(!checked),
            child: _CheckCircle(checked: checked),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!checked),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onViewTap,
            child: const Text(
              '보기',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A67F2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 연령 확인 항목 (별도 UI) ─────────────────────────────

class _AgeConsentItem extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool?> onChanged;

  const _AgeConsentItem({required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E7EF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CheckCircle(checked: checked),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[필수] 만 14세 이상 확인',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '만 14세 미만은 서비스를 이용할 수 없습니다.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 체크 원형 아이콘 ─────────────────────────────────────

class _CheckCircle extends StatelessWidget {
  final bool checked;

  const _CheckCircle({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? const Color(0xFF4A67F2) : Colors.white,
        border: Border.all(
          color: checked ? const Color(0xFF4A67F2) : const Color(0xFFCBD1DB),
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

// ─── 하단 안내 문구 ───────────────────────────────────────

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 11,
          height: 1.6,
          color: Color(0xFF9AA7B2),
        ),
        children: [
          const TextSpan(
            text: '동의 후 수집된 개인정보는 서비스 제공 목적으로만 사용됩니다. '
                '자세한 내용은 ',
          ),
          TextSpan(
            text: '개인정보처리방침',
            style: const TextStyle(
              color: Color(0xFF4A67F2),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push(AppRoutes.privacyPolicy),
          ),
          const TextSpan(text: '을 확인하세요.'),
        ],
      ),
    );
  }
}
