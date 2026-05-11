import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        title: Text('개인정보처리방침', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary)),
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
          title: '1. 이용 대상 및 연령 제한',
          body: '본 서비스는 만 15세 이상 고등학교 재학생을 대상으로 합니다. '
              '만 14세 미만은 서비스를 이용할 수 없으며, 만 14세 미만으로 확인될 경우 계정은 즉시 삭제됩니다. '
              '만 14세 이상 만 19세 미만 이용자는 법정대리인의 동의 없이 가입할 수 있으나, '
              '법정대리인이 이의를 제기하는 경우 관련 처리 절차에 따릅니다.',
        ),
        _Section(
          title: '2. 수집하는 개인정보 항목',
          body: '서비스는 다음 항목을 수집합니다.\n\n'
              '• 필수 수집 항목: 이메일 주소, 비밀번호(암호화 저장), 이름, 닉네임, 성별, 학교명, 학년, '
              '휴대전화번호, 학생증 인증 이미지\n'
              '• 서비스 이용 중 자동 수집: 접속 기록, 기기 정보(OS 종류), 푸시 알림 토큰\n\n'
              '성별 정보는 서비스 내 맞춤 콘텐츠 제공과 통계 분석 목적으로 수집되며, '
              '다른 이용자에게는 공개되지 않습니다.',
        ),
        _Section(
          title: '3. 이용 목적',
          body: '수집한 정보는 회원 식별, 학교 인증, 커뮤니티 서비스 제공, 알림 발송, '
              '신고·분쟁 처리, 청소년 보호, 부정 이용 방지, 법령 준수를 위해 이용합니다.',
        ),
        _Section(
          title: '4. 보유 및 이용 기간',
          body: '개인정보는 아래 기준에 따라 보유·삭제합니다.\n\n'
              '• 회원 정보(이메일·이름·닉네임 등): 회원 탈퇴 즉시 파기\n'
              '• 학생증 인증 이미지: 인증 승인 또는 최종 거절 후 30일 이내 파기\n'
              '• 서비스 이용 기록(로그인 이력·접속 기록): 3개월 보관 후 파기\n'
              '• 게시물·댓글: 회원 탈퇴 시 익명 처리 또는 삭제\n'
              '• 채팅 메시지: 채팅방 삭제 또는 회원 탈퇴 시 파기\n\n'
              '단, 전자상거래 등에서의 소비자보호에 관한 법률, '
              '통신비밀보호법 등 관계 법령에서 정한 경우에는 해당 기간 동안 보관합니다.',
        ),
        _Section(
          title: '5. 익명 게시물과 운영자 접근',
          body: '익명 게시물은 일반 이용자에게 작성자 실명·연락처 등 직접 식별 정보를 노출하지 않습니다. '
              '다만 신고 대응, 안전 운영, 법령 준수, 분쟁 대응을 위해 권한을 부여받은 운영자가 '
              '필요한 최소 범위의 게시물·댓글·신고 정보·제재 이력을 확인할 수 있습니다. '
              '운영자 열람 및 주요 조치는 감사 로그로 기록하고 관리합니다.',
        ),
        _Section(
          title: '6. 제3자 제공',
          body: '서비스는 이용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다. '
              '단, 이용자 동의가 있거나 법령에 따른 요청이 있는 경우 예외적으로 제공될 수 있습니다.',
        ),
        _Section(
          title: '7. 처리 위탁 (수탁업체 목록)',
          body: '서비스 운영을 위해 아래 업체에 일부 업무를 위탁합니다.\n\n'
              '• Amazon Web Services, Inc. (AWS)\n'
              '  위탁 내용: 서버 인프라 운영, 이미지·파일 저장 (Amazon S3), 이미지 콘텐츠 검수 (Amazon Rekognition)\n'
              '  보유 기간: 위탁 계약 종료 시까지\n\n'
              '• Google LLC (Firebase)\n'
              '  위탁 내용: 푸시 알림 발송 (Firebase Cloud Messaging), 앱 분석\n'
              '  보유 기간: 위탁 계약 종료 시까지\n\n'
              '위탁업체에 대해서는 개인정보 보호에 필요한 기술적·관리적 조치를 계약에 명시하고 있습니다.',
        ),
        _Section(
          title: '8. 안전성 확보 조치',
          body: '서비스는 접근 권한 최소화, 전송 구간 암호화(HTTPS/TLS), 비밀번호 단방향 암호화, '
              '토큰 암호화 저장, 접속 기록 관리, 정기 보안 점검 등 개인정보 보호를 위한 '
              '기술적·관리적 조치를 시행합니다.',
        ),
        _Section(
          title: '9. 이용자의 권리',
          body: '이용자는 개인정보 열람, 정정, 삭제, 처리 정지, 동의 철회를 요청할 수 있습니다. '
              '앱 내 설정 → 회원 탈퇴를 통해 계정 삭제 및 개인정보 파기를 요청할 수 있습니다. '
              '기타 개인정보 관련 문의는 아래 연락처로 접수할 수 있습니다.\n\n'
              '개인정보 보호 책임자: privacy@teenple.com',
        ),
        _Section(
          title: '10. 방침 변경',
          body: '개인정보처리방침은 법령, 정책, 서비스 변경에 따라 수정될 수 있으며, '
              '중요한 변경은 앱 내 공지 등 적절한 방법으로 최소 7일 전 안내합니다.',
        ),
        _Section(
          title: '11. 시행일',
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 12, height: 1.7, color: c.textBody)),
        ],
      ),
    );
  }
}
