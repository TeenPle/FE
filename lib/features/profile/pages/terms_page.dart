import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
          '이용약관',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: _TermsContent(),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: '제1조 (목적)',
          body: '이 약관은 Teenple(이하 "서비스") 운영자가 제공하는 학교 커뮤니티 서비스의 이용 조건 및 절차, 운영자와 회원 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.',
        ),
        _Section(
          title: '제2조 (운영자 정보)',
          body: '• 운영자: [이름]\n'
              '• 이메일: support@teenple.com',
        ),
        _Section(
          title: '제3조 (약관의 게시 및 개정)',
          body: '① 회사는 이 약관의 내용을 서비스 내 설정 화면에 게시합니다.\n'
              '② 회사는 합리적인 사유가 있는 경우 관련 법령을 위반하지 않는 범위 내에서 약관을 개정할 수 있습니다.\n'
              '③ 약관을 개정하는 경우 적용일 7일 전(회원에게 불리한 변경의 경우 30일 전)에 앱 공지사항을 통해 고지합니다.\n'
              '④ 변경된 약관에 동의하지 않는 경우 회원은 서비스 이용을 중단하고 탈퇴할 수 있습니다.',
        ),
        _Section(
          title: '제4조 (이용 대상)',
          body: '서비스는 재학 중인 고등학생을 주요 이용 대상으로 합니다. 회원가입 시 학교 인증을 완료한 사용자에 한해 서비스를 이용할 수 있습니다.\n'
              '미성년자가 이 약관에 동의하고 서비스에 가입하는 경우, 법정대리인이 동의한 것으로 간주합니다.',
        ),
        _Section(
          title: '제5조 (회원의 의무)',
          body: '회원은 다음 행위를 하여서는 안 됩니다.\n'
              '1. 타인의 개인정보를 무단으로 수집·저장·공개하는 행위\n'
              '2. 음란, 폭력적이거나 혐오스러운 게시물을 작성하거나 유포하는 행위\n'
              '3. 서비스의 운영을 고의로 방해하는 행위\n'
              '4. 다른 회원을 괴롭히거나 명예를 훼손하는 행위\n'
              '5. 타인의 계정을 도용하거나 허위 정보로 가입하는 행위\n'
              '6. 영리 목적의 광고·홍보 게시물을 무단으로 게시하는 행위\n'
              '7. 관련 법령 또는 이 약관을 위반하는 행위',
        ),
        _Section(
          title: '제6조 (서비스 제공 및 변경)',
          body: '① 서비스는 연중무휴, 1일 24시간 제공을 원칙으로 합니다.\n'
              '② 시스템 점검·장애·서비스 개선 등의 사유로 일시 중단될 수 있으며, 이 경우 사전 또는 사후 공지합니다.\n'
              '③ 회사는 서비스의 내용·이용 방법·이용 시간을 변경할 수 있으며, 변경 사항은 사전 공지합니다.',
        ),
        _Section(
          title: '제7조 (게시물 관리 및 저작권)',
          body: '① 회원이 서비스 내에 작성·게시한 게시물의 저작권은 해당 게시물을 작성한 회원에게 귀속됩니다.\n'
              '② 회원은 서비스 이용 과정에서 자신이 게시한 게시물을 회사가 서비스 운영·개선·홍보 목적으로 활용할 수 있도록 이용을 허락합니다.\n'
              '③ 회사는 미성년자 보호, 명예훼손, 개인정보 침해, 관련 법령 위반 등의 사유가 있는 게시물에 대해 사전 통보 없이 삭제하거나 이용을 제한할 수 있습니다.\n'
              '④ 회원은 자신이 게시한 게시물이 타인의 권리를 침해하지 않도록 해야 하며, 이로 인한 분쟁에 대해 회사는 책임을 지지 않습니다.',
        ),
        _Section(
          title: '제8조 (이용 제한 및 제재)',
          body: '① 회사는 회원이 제5조의 의무를 위반하거나 서비스 운영을 방해한 경우 경고, 일시 정지, 영구 이용 제한 등의 조치를 취할 수 있습니다.\n'
              '② 이용 제한 처분에 이의가 있는 회원은 처분 통지를 받은 날로부터 7일 이내에 support@teenple.com으로 이의신청을 할 수 있습니다.\n'
              '③ 회사는 이의신청을 접수한 날로부터 7일 이내에 처리 결과를 통보합니다.',
        ),
        _Section(
          title: '제9조 (회원 탈퇴 및 자격 상실)',
          body: '① 회원은 언제든지 서비스 내 설정 화면을 통해 탈퇴를 신청할 수 있으며, 회사는 즉시 처리합니다.\n'
              '② 회원이 탈퇴하면 관련 법령 및 개인정보처리방침에 따라 개인정보가 파기됩니다. 단, 다른 회원과의 커뮤니티 활동으로 인한 게시물은 탈퇴 후에도 서비스 내에 남을 수 있습니다.',
        ),
        _Section(
          title: '제10조 (책임의 한계)',
          body: '① 회사는 천재지변, 불가항력적 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다.\n'
              '② 회사는 회원 간 또는 회원과 제3자 간의 분쟁에 대하여 개입할 의무가 없으며, 이로 인한 손해에 대해 책임을 지지 않습니다.\n'
              '③ 회원의 귀책사유로 인한 서비스 이용 장애에 대해 회사는 책임을 지지 않습니다.',
        ),
        _Section(
          title: '제11조 (서비스 종료)',
          body: '회사가 서비스를 종료하는 경우 최소 30일 전에 앱 공지사항 및 등록된 이메일을 통해 고지합니다. 서비스 종료 시 회원의 개인정보는 개인정보처리방침에 따라 파기됩니다.',
        ),
        _Section(
          title: '제12조 (준거법 및 관할법원)',
          body: '① 이 약관은 대한민국 법률에 따라 해석·적용됩니다.\n'
              '② 서비스 이용과 관련하여 회사와 회원 간에 발생한 분쟁에 대해서는 민사소송법상의 관할법원을 제1심 법원으로 합니다.',
        ),
        _Section(
          title: '부칙',
          body: '본 약관은 2025년 1월 1일부터 시행합니다.',
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
