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
        title: const Text('개인정보처리방침', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
          title: '1. 수집하는 개인정보',
          body: '서비스는 회원가입, 학교 인증, 서비스 이용 과정에서 이메일, 비밀번호, 휴대전화번호, 학교명, 학년·반, 학생증 인증 자료, 접속 기록, 기기 정보, 푸시 토큰 등 필요한 정보를 수집할 수 있습니다.',
        ),
        _Section(
          title: '2. 이용 목적',
          body: '수집한 정보는 회원 식별, 학교 인증, 커뮤니티 제공, 알림 발송, 신고 처리, 청소년 보호, 부정 이용 방지, 분쟁 대응, 법령 준수를 위해 이용합니다.',
        ),
        _Section(
          title: '3. 익명 게시물과 운영자 접근',
          body: '익명 게시물은 일반 이용자에게 작성자 실명, 연락처 등 직접 식별 정보를 노출하지 않습니다. 다만 신고 대응, 안전 운영, 법령 준수, 분쟁 대응을 위해 권한을 부여받은 운영자가 필요한 최소 범위의 게시물, 댓글, 신고 정보, 제재 이력을 확인할 수 있습니다. 운영자 열람 및 주요 조치는 감사 로그로 기록하고 관리합니다.',
        ),
        _Section(
          title: '4. 보유 및 이용 기간',
          body: '개인정보는 회원 탈퇴 또는 이용 목적 달성 시 지체 없이 파기합니다. 다만 관계 법령 준수, 신고·분쟁 처리, 부정 이용 방지를 위해 필요한 기록은 정해진 기간 동안 보관할 수 있습니다.',
        ),
        _Section(
          title: '5. 제3자 제공',
          body: '서비스는 이용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다. 단, 이용자 동의가 있거나 법령에 따른 요청이 있는 경우 예외적으로 제공될 수 있습니다.',
        ),
        _Section(
          title: '6. 처리 위탁',
          body: '서비스 운영을 위해 서버 인프라, 파일 저장, 푸시 알림 등 일부 업무를 외부 서비스 제공자에게 위탁할 수 있으며, 위탁 시 개인정보 보호에 필요한 조치를 취합니다.',
        ),
        _Section(
          title: '7. 안전성 확보 조치',
          body: '서비스는 접근 권한 최소화, 전송 구간 암호화, 비밀번호 암호화, 접속 기록 관리, 보안 점검 등 개인정보 보호를 위한 기술적·관리적 조치를 시행합니다.',
        ),
        _Section(
          title: '8. 이용자의 권리',
          body: '이용자는 개인정보 열람, 정정, 삭제, 처리 정지, 동의 철회를 요청할 수 있습니다. 관련 문의는 privacy@teenple.com으로 접수할 수 있습니다.',
        ),
        _Section(
          title: '9. 방침 변경',
          body: '개인정보처리방침은 법령, 정책, 서비스 변경에 따라 수정될 수 있으며, 중요한 변경은 앱 내 공지 등 적절한 방법으로 안내합니다.',
        ),
        _Section(
          title: '10. 시행일',
          body: '본 개인정보처리방침은 2026년 5월 8일부터 시행합니다.',
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
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 12, height: 1.7, color: Color(0xFF444444))),
        ],
      ),
    );
  }
}
