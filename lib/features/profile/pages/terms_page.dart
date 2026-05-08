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
        title: const Text('이용약관', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
          title: '1. 목적',
          body: '이 약관은 Teenple 서비스의 이용 조건, 회원과 운영자의 권리·의무, 커뮤니티 운영 기준을 정합니다.',
        ),
        _Section(
          title: '2. 이용 대상',
          body: '서비스는 학교 인증을 완료한 학생을 주요 대상으로 하며, 회원은 본인 정보로 가입하고 커뮤니티 규칙을 준수해야 합니다.',
        ),
        _Section(
          title: '3. 금지 행위',
          body: '타인의 권리 침해, 명예훼손, 괴롭힘, 혐오 표현, 불법 정보 게시, 광고성 게시, 계정 도용, 서비스 운영 방해 행위를 금지합니다.',
        ),
        _Section(
          title: '4. 게시물 관리',
          body: '회원이 작성한 게시물의 권리는 회원에게 있습니다. 다만 운영자는 신고 처리, 안전 점검, 법령 준수, 서비스 운영을 위해 필요한 범위에서 게시물을 확인하고 숨김, 삭제, 경고, 이용 제한 등의 조치를 할 수 있습니다.',
        ),
        _Section(
          title: '5. 익명 커뮤니티와 운영자 열람 제한',
          body: '익명 게시물은 일반 이용자에게 작성자 실명이나 연락처를 노출하지 않습니다. 운영자 열람은 신고 대응, 청소년 보호, 안전 운영, 법령 준수, 분쟁 대응 목적에 필요한 최소 범위로 제한합니다. 운영자의 게시물 상세 열람과 숨김·복구, 신고 처리, 제재 취소 등 주요 조치는 감사 로그로 기록합니다.',
        ),
        _Section(
          title: '6. 신고 및 제재',
          body: '회원은 부적절한 게시물, 댓글, 이용자를 신고할 수 있습니다. 운영자는 신고 내용을 검토한 뒤 경고, 게시물 숨김, 일시 이용 제한, 제재 취소 등 필요한 조치를 할 수 있으며, 처리 사유를 내부 기록으로 보관합니다.',
        ),
        _Section(
          title: '7. 이의 제기',
          body: '제재 또는 게시물 조치에 이의가 있는 회원은 support@teenple.com으로 문의할 수 있습니다. 운영자는 접수된 문의를 검토하여 합리적인 기간 내 답변합니다.',
        ),
        _Section(
          title: '8. 약관 변경',
          body: '운영자는 법령, 정책, 서비스 변경에 따라 약관을 변경할 수 있습니다. 중요한 변경은 사전에 앱 내 공지 또는 적절한 방법으로 안내합니다.',
        ),
        _Section(
          title: '9. 시행일',
          body: '본 약관은 2026년 5월 8일부터 시행합니다.',
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
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF444444))),
        ],
      ),
    );
  }
}
