import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const _termsUrl = 'https://www.notion.so/7715bdc3bc8c479c859d6716aa4bfeac';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  /// 설정 화면의 이용약관은 핵심 요약을 먼저 제공하고,
  /// 법적 원문은 외부 Notion 문서에서 확인하도록 연결합니다.
  Future<void> _openTermsUrl(BuildContext context) async {
    final uri = Uri.parse(_termsUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 이용약관을 열 수 없어요. 잠시 후 다시 시도해 주세요.')),
    );
  }

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
        title: Text(
          '이용약관',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: _TermsContent(
          onOpenOriginalDocument: () => _openTermsUrl(context),
        ),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  final VoidCallback onOpenOriginalDocument;

  const _TermsContent({required this.onOpenOriginalDocument});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Section(
          title: '서비스 개요',
          body:
              'TeenPle은 학교 인증을 완료한 고등학생들이 게시글, 댓글, 채팅, 신고, 알림 등을 통해 소통하는 학교 기반 커뮤니티 서비스입니다. 본 약관은 서비스 이용 조건과 회원·운영자의 권리와 의무를 정합니다.',
        ),
        const _Section(
          title: '가입 및 인증',
          body:
              '서비스는 대한민국 고등학교 재학생 또는 이에 준하는 이용자를 주요 대상으로 합니다. 회원은 본인의 실제 정보로 가입해야 하며, 학교 인증, 학생증 인증, 이메일 인증, 휴대전화번호 확인 등 필요한 절차를 완료해야 할 수 있습니다.',
        ),
        const _Section(
          title: '계정 관리',
          body:
              '회원은 본인의 계정과 기기를 안전하게 관리해야 하며, 계정을 타인에게 양도, 대여, 공유해서는 안 됩니다. 허위 가입, 타인 정보 이용, 사칭, 인증 자료 조작, 계정 공유가 확인되면 이용 제한 또는 계정 삭제가 이루어질 수 있습니다.',
        ),
        const _Section(
          title: '서비스 이용 및 변경',
          body:
              '회원은 본 약관, 운영정책 및 관련 법령을 준수해야 합니다. 운영자는 서비스 개선, 기능 변경, 점검, 장애 대응, 보안 조치, 정책 변경 등의 사유로 서비스의 전부 또는 일부를 변경하거나 일시 중단할 수 있습니다.',
        ),
        const _Section(
          title: '개인정보 및 청소년 보호',
          body:
              '운영자는 개인정보를 개인정보처리방침에 따라 처리하며, 청소년 유해 정보 차단, 신고 처리, 이용 제한 등 청소년 보호 조치를 시행할 수 있습니다. 회원은 타인의 개인정보, 사진, 연락처, SNS 계정, 위치 정보 등을 동의 없이 게시하거나 유포해서는 안 됩니다.',
        ),
        const _Section(
          title: '금지 행위',
          body:
              '회원은 학교폭력, 따돌림, 괴롭힘, 협박, 혐오·차별 표현, 특정 학생·교사·학교에 대한 비방이나 허위 사실 유포, 성적 수치심을 유발하는 표현, 불법·유해·광고성 게시물, 도배, 분쟁 유도, 신고 기능 악용, 운영자 또는 회원 사칭, 타인의 권리·명예·사생활 침해 행위를 해서는 안 됩니다.',
        ),
        const _Section(
          title: '콘텐츠 권리와 관리',
          body:
              '회원이 작성한 게시글, 댓글, 채팅 등 콘텐츠의 권리는 원칙적으로 해당 회원에게 있습니다. 다만 회원은 서비스 내 게시, 노출, 저장, 전송, 검색, 추천, 알림, 신고 처리, 분쟁 대응, 운영정책 집행에 필요한 범위에서 운영자가 콘텐츠를 이용할 수 있도록 허락합니다.',
        ),
        const _Section(
          title: '신고 및 제재',
          body:
              '회원은 부적절한 콘텐츠 또는 이용자를 신고할 수 있습니다. 운영자는 신고 내용, 이용 기록, 콘텐츠 내용을 검토하여 게시물·댓글·채팅 삭제 또는 임시 숨김, 경고, 일정 기간 이용 제한, 영구 이용 제한, 계정 삭제 등의 조치를 할 수 있습니다. 반복 위반 또는 중대한 위반에는 더 강한 제재가 적용될 수 있습니다.',
        ),
        const _Section(
          title: '탈퇴 및 복구',
          body:
              '회원은 언제든지 서비스 내 기능을 통해 탈퇴를 요청할 수 있습니다. 탈퇴 요청 후 계정 처리 및 복구 가능 여부, 개인정보와 콘텐츠 처리 및 보관 기간은 개인정보처리방침 및 운영정책에 따릅니다.',
        ),
        const _Section(
          title: '책임 및 분쟁 해결',
          body:
              '운영자는 회원이 작성한 콘텐츠의 정확성, 신뢰성, 적법성을 보증하지 않으며, 회원 간 또는 회원과 제3자 간 분쟁은 당사자 간 해결을 원칙으로 합니다. 다만 운영자는 관련 법령과 운영정책에 따라 필요한 조치를 할 수 있으며, 운영자의 고의 또는 중대한 과실로 인한 책임은 관련 법령에 따릅니다.',
        ),
        const _Section(
          title: '약관 변경 및 시행일',
          body:
              '운영자는 관련 법령을 위반하지 않는 범위에서 약관을 변경할 수 있으며, 변경 내용은 서비스 내 공지사항 또는 별도 안내를 통해 고지합니다. 본 약관은 대한민국 법령에 따라 해석되며, 2026년 5월 8일부터 시행합니다.',
        ),
        TextButton.icon(
          onPressed: onOpenOriginalDocument,
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text('전체 이용약관 보기'),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: const Color(0xFF4A67F2),
            padding: EdgeInsets.zero,
            textStyle: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
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
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              height: 1.7,
              color: c.textBody,
            ),
          ),
        ],
      ),
    );
  }
}
