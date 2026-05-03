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
          body:
              '이 약관은 Teenple(이하 "서비스")이 제공하는 학교 커뮤니티 서비스의 이용 조건 및 절차, 회사와 회원 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.',
        ),
        _Section(
          title: '제2조 (이용 대상)',
          body:
              '서비스는 재학 중인 중·고등학생을 주요 이용 대상으로 합니다. 회원가입 시 학교 인증을 완료한 사용자에 한해 서비스를 이용할 수 있습니다.',
        ),
        _Section(
          title: '제3조 (회원의 의무)',
          body: '회원은 다음 행위를 하여서는 안 됩니다.\n'
              '1. 타인의 개인정보를 수집·저장·공개하는 행위\n'
              '2. 음란, 폭력적인 게시물을 작성하거나 유포하는 행위\n'
              '3. 서비스의 운영을 고의로 방해하는 행위\n'
              '4. 다른 회원을 괴롭히거나 명예를 훼손하는 행위',
        ),
        _Section(
          title: '제4조 (서비스 제공 및 변경)',
          body:
              '서비스는 연중무휴, 1일 24시간 제공을 원칙으로 합니다. 단, 시스템 점검 등의 사유로 일시 중단될 수 있으며, 이 경우 사전 공지합니다.',
        ),
        _Section(
          title: '제5조 (게시물 관리)',
          body:
              '회원이 작성한 게시물은 서비스 내에서 공개됩니다. 서비스는 미성년자 보호 및 관련 법령 위반 게시물에 대해 사전 통보 없이 삭제하거나 이용을 제한할 수 있습니다.',
        ),
        _Section(
          title: '제6조 (책임의 한계)',
          body:
              '서비스는 회원 간 분쟁에 대하여 개입할 의무가 없으며, 회원의 귀책사유로 인한 손해에 대하여 책임을 지지 않습니다.',
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
