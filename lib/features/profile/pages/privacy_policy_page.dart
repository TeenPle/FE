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
              '• 서비스 이용 중 자동 수집: 접속 IP, 기기 정보(기기 식별자, OS 버전), 서비스 이용 기록, 푸시 알림 토큰',
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
          body: '회원 탈퇴 시 지체 없이 파기합니다. 단, 관련 법령에 따라 보존이 필요한 경우 해당 기간 동안 보관합니다.\n'
              '• 전자상거래 관련 기록: 5년\n'
              '• 소비자 불만 및 분쟁 처리 기록: 3년\n'
              '• 접속 로그 기록: 3개월 (통신비밀보호법)\n\n'
              '[파기 방법]\n'
              '• 전자적 파일: 복구 불가능한 기술적 방법으로 영구 삭제\n'
              '• 출력물: 분쇄 또는 소각 처리',
        ),
        _Section(
          title: '4. 개인정보의 제3자 제공',
          body: '서비스는 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 다만, 이용자의 사전 동의가 있거나 법령에 의한 경우는 예외로 합니다.',
        ),
        _Section(
          title: '5. 개인정보 처리 위탁',
          body: '서비스는 원활한 서비스 제공을 위해 다음과 같이 개인정보 처리를 위탁합니다.\n\n'
              '• 수탁업체: Amazon Web Services (AWS)\n'
              '  위탁 업무: 서버 운영 및 데이터 저장\n\n'
              '• 수탁업체: Google Firebase (Google LLC)\n'
              '  위탁 업무: 푸시 알림 발송',
        ),
        _Section(
          title: '6. 개인정보의 국외 이전',
          body: '서비스는 아래와 같이 개인정보를 국외로 이전합니다. 서비스 이용을 통해 본 방침에 동의하는 경우 국외 이전에 동의한 것으로 간주됩니다.\n\n'
              '• 이전받는 자: Amazon Web Services, Inc.\n'
              '  이전 국가: 미국\n'
              '  이전 목적: 서버 운영 및 데이터 저장\n'
              '  보유·이용 기간: 회원 탈퇴 시 또는 위탁 계약 종료 시까지\n\n'
              '• 이전받는 자: Google LLC\n'
              '  이전 국가: 미국\n'
              '  이전 목적: 푸시 알림 서비스 제공\n'
              '  보유·이용 기간: 회원 탈퇴 시 또는 위탁 계약 종료 시까지',
        ),
        _Section(
          title: '7. 개인정보의 안전성 확보 조치',
          body: '서비스는 개인정보보호법 제29조에 따라 다음과 같은 안전성 확보 조치를 취하고 있습니다.\n'
              '• 비밀번호 암호화: 이용자의 비밀번호는 단방향 암호화(해시)하여 저장\n'
              '• 전송 구간 암호화: 개인정보는 HTTPS/TLS를 통해 암호화 전송\n'
              '• 접근 권한 관리: 개인정보 처리 담당자를 최소화하고 접근 권한을 제한\n'
              '• 접속 기록 보관: 개인정보 처리 시스템 접속 기록을 보관·관리\n'
              '• 보안 취약점 점검: 주기적으로 보안 취약점을 점검하고 조치',
        ),
        _Section(
          title: '8. 이용자의 권리 및 행사 방법',
          body: '이용자는 언제든지 다음 권리를 행사할 수 있습니다.\n'
              '• 개인정보 열람 요청\n'
              '• 개인정보 정정·삭제 요청\n'
              '• 개인정보 처리정지 요청\n'
              '• 동의 철회 요청\n\n'
              '권리 행사는 아래 개인정보 보호책임자에게 이메일로 요청하시면 되며, 서비스는 요청 접수 후 10일 이내에 처리합니다. 단, 법령에 의한 보존 의무가 있는 경우 삭제가 제한될 수 있습니다.',
        ),
        _Section(
          title: '9. 권리 침해 시 구제 방법',
          body: '개인정보 침해로 인한 신고·상담은 아래 기관에 문의하실 수 있습니다.\n\n'
              '• 개인정보분쟁조정위원회: www.kopico.go.kr / 1833-6972\n'
              '• 개인정보보호위원회: www.pipc.go.kr / 국번없이 182\n'
              '• 한국인터넷진흥원(KISA) 개인정보침해 신고센터: privacy.kisa.or.kr / 국번없이 118\n'
              '• 대검찰청 사이버수사과: www.spo.go.kr / 국번없이 1301\n'
              '• 경찰청 사이버수사국: ecrm.cyber.go.kr / 국번없이 182',
        ),
        _Section(
          title: '10. 개인정보처리방침의 변경',
          body: '이 개인정보처리방침은 법령·정책 또는 보안 기술의 변경에 따라 내용이 추가·삭제·수정될 수 있습니다. 방침 변경 시에는 시행 7일 전(이용자에게 불리한 변경의 경우 30일 전)에 앱 공지사항을 통해 사전 고지합니다.',
        ),
        _Section(
          title: '11. 개인정보 보호책임자',
          body: '• 직책: 개인정보 보호책임자\n'
              '• 이메일: privacy@teenple.com\n\n'
              '개인정보 관련 문의, 불만 처리, 피해 구제 등에 관한 사항은 위 연락처로 문의하시기 바랍니다.\n\n'
              '시행일: 2025년 1월 1일',
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
