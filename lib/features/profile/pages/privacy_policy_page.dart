import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: const Text(
          '개인정보처리방침',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: _PrivacyContent(),
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: '1. 수집하는 개인정보 항목',
          body: '서비스는 회원가입 및 서비스 이용 과정에서 다음의 개인정보를 수집합니다.\n'
              '• 필수항목: 이름, 이메일 주소, 비밀번호, 휴대폰 번호, 학교명, 학년·반\n'
              '• 서비스 이용 중 자동 수집: 접속 IP, 기기 정보, 서비스 이용 기록',
        ),
        _Section(
          title: '2. 개인정보의 수집 및 이용 목적',
          body: '수집한 개인정보는 다음 목적으로만 이용됩니다.\n'
              '• 회원 식별 및 본인 확인\n'
              '• 학교 인증 처리\n'
              '• 서비스 이용 및 고객 지원\n'
              '• 알림 발송 (댓글, 공지 등)\n'
              '• 불량 이용자 제재 및 분쟁 처리',
        ),
        _Section(
          title: '3. 개인정보의 보유 및 이용 기간',
          body: '회원 탈퇴 시 즉시 파기합니다. 단, 관련 법령에 따라 일정 기간 보존이 필요한 경우 해당 기간 동안 보관합니다.\n'
              '• 전자상거래 관련 기록: 5년\n'
              '• 소비자 불만 및 분쟁 처리 기록: 3년',
        ),
        _Section(
          title: '4. 개인정보의 제3자 제공',
          body:
              '서비스는 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 다만, 이용자의 동의가 있거나 법령에 의한 경우는 예외로 합니다.',
        ),
        _Section(
          title: '5. 개인정보 처리 위탁',
          body: '서비스는 다음 업체에 개인정보 처리를 위탁합니다.\n'
              '• Amazon Web Services (AWS): 서버 운영 및 데이터 저장\n'
              '• Google Firebase: 푸시 알림 발송',
        ),
        _Section(
          title: '6. 이용자의 권리',
          body:
              '이용자는 언제든지 자신의 개인정보를 조회·수정하거나 탈퇴를 통해 삭제를 요청할 수 있습니다. 개인정보 관련 문의는 아래 연락처로 하시기 바랍니다.',
        ),
        _Section(
          title: '7. 개인정보 보호책임자',
          body: '• 이메일: privacy@teenple.com\n'
              '• 시행일: 2025년 1월 1일',
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}
