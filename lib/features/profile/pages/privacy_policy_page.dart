import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const _privacyPolicyUrl =
    'https://www.notion.so/72fe902f12d6402e8ba4c51733d9558f';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  /// 프로필/설정 화면에는 핵심 방침을 앱 안에서 먼저 고지하고,
  /// 세부 조항과 변경 이력은 배포용 Notion 원문에서 확인하게 합니다.
  Future<void> _openPrivacyPolicyUrl(BuildContext context) async {
    final uri = Uri.parse(_privacyPolicyUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 개인정보처리방침을 열 수 없어요. 잠시 후 다시 시도해 주세요.')),
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
          '개인정보처리방침',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: _PrivacyContent(
          onOpenOriginalDocument: () => _openPrivacyPolicyUrl(context),
        ),
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  final VoidCallback onOpenOriginalDocument;

  const _PrivacyContent({required this.onOpenOriginalDocument});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Section(
          title: '개인정보처리방침 안내',
          body:
              'TeenPle은 이용자의 개인정보를 중요하게 생각하며, 「개인정보 보호법」 등 관련 법령을 준수합니다.\n\n'
              '본 개인정보처리방침은 TeenPle이 개인정보를 어떤 목적으로 처리하고, 어떤 항목을 수집하며, 어떻게 보관·파기하는지 안내하기 위한 문서입니다.',
        ),
        const _Section(
          title: '개인정보 처리 목적',
          body:
              'TeenPle은 회원가입, 학교 인증, 서비스 제공, 계정 보호, 신고 처리, 분쟁 대응, 청소년 보호, 유해 이미지 탐지, 서비스 보안 관리 및 고객 지원을 위해 개인정보를 처리합니다.',
        ),
        const _Section(
          title: '처리하는 개인정보 항목',
          body:
              'TeenPle은 회원가입 시 이름, 닉네임, 성별, 이메일 주소, 비밀번호, 휴대전화번호, 학교명, 학년을 처리합니다.\n\n'
              '학교 인증을 위해 학생증 인증 이미지, 학생증 이미지에 포함된 인증 필요 정보, 인증 상태, 인증 요청·처리 일시, 인증 반려 사유 등을 처리할 수 있습니다.\n\n'
              '서비스 이용 과정에서 접속 일시, IP 주소, 기기 정보, OS 정보, 앱 버전 정보, 푸시 알림 토큰, 게시글, 댓글, 채팅, 이미지, 첨부 파일, 신고 및 제재 이력, 서비스 이용 활동 기록, 유해 이미지 탐지 결과가 생성 또는 처리될 수 있습니다.',
        ),
        const _Section(
          title: '학생증 인증',
          body:
              '학생증 이미지에는 이름, 학교명, 학년, 사진, 학번, 생년월일 등이 포함될 수 있습니다.\n\n'
              '회원은 학생증 업로드 시 학교 재학생 여부 확인에 필요하지 않은 정보는 가린 후 제출할 수 있습니다. TeenPle은 학교 인증에 필요한 범위에서만 학생증 이미지를 확인합니다.',
        ),
        const _Section(
          title: '보유 및 파기',
          body:
              'TeenPle은 개인정보 처리 목적이 달성되면 지체 없이 개인정보를 파기합니다.\n\n'
              '회원 계정 정보는 회원 탈퇴 완료 시까지 보관하며, 탈퇴 완료 후 삭제 또는 익명 처리됩니다.\n\n'
              '학생증 인증 이미지는 학교 인증 승인 또는 거절 처리 완료 시까지 보관하며, 인증 처리 후 지체 없이 삭제됩니다.\n\n'
              '서비스 이용 기록 및 접속 기록은 부정 이용 방지, 보안 점검, 장애 대응, 분쟁 대응을 위해 수집일로부터 최대 1년간 보관될 수 있습니다.\n\n'
              '신고 및 제재 이력은 반복 위반 방지, 청소년 보호, 분쟁 대응을 위해 처리 완료일 또는 제재 종료일로부터 최대 3년간 보관될 수 있습니다.\n\n'
              '게시글, 댓글, 채팅, 이미지 등 콘텐츠는 서비스 제공 및 운영에 필요한 기간 동안 보관되며, 회원 탈퇴 시 삭제 또는 익명 처리될 수 있습니다. 다만 신고 처리, 분쟁 대응, 법령 위반 확인이 필요한 경우 해당 목적 달성 시까지 보관될 수 있습니다.',
        ),
        const _Section(
          title: '제3자 제공 및 처리 위탁',
          body:
              'TeenPle은 원칙적으로 회원의 개인정보를 제3자에게 제공하지 않습니다. 다만 회원이 동의한 경우, 법령에 따른 요청이 있는 경우, 생명·신체·재산 보호를 위해 긴급히 필요한 경우에는 예외적으로 제공될 수 있습니다.\n\n'
              'TeenPle은 안정적인 서비스 제공을 위해 개인정보 처리 업무의 일부를 외부 업체에 위탁할 수 있습니다.\n\n'
              '현재 Amazon Web Services, Inc.를 통해 서버 인프라 운영, 데이터베이스 저장 및 관리, 이미지 및 파일 저장, 서비스 로그 보관, 보안 모니터링, 유해 이미지 탐지 업무를 처리할 수 있습니다.\n\n'
              '또한 Google LLC의 Firebase Cloud Messaging을 통해 푸시 알림 발송 업무를 처리할 수 있습니다.',
        ),
        const _Section(
          title: '국외 이전',
          body:
              'TeenPle은 현재 회원의 개인정보를 국외로 이전하지 않습니다.\n\n'
              '향후 개인정보의 국외 이전이 발생하는 경우 관련 법령에 따라 이전받는 자, 이전 국가, 이전 항목, 이전 목적, 보유 및 이용 기간 등을 안내하고 필요한 조치를 이행합니다.',
        ),
        const _Section(
          title: '이용자의 권리',
          body:
              '회원은 본인의 개인정보에 대해 열람, 정정, 삭제, 처리 정지, 동의 철회, 회원 탈퇴를 요청할 수 있습니다.\n\n'
              'TeenPle은 회원의 요청을 확인한 후 관련 법령에 따라 필요한 조치를 합니다. 다만 법령상 보관이 필요한 정보, 부정 이용 방지 또는 분쟁 대응에 필요한 정보는 일정 기간 보관될 수 있습니다.',
        ),
        const _Section(
          title: '개인정보 보호조치',
          body:
              'TeenPle은 비밀번호 일방향 암호화, 개인정보 접근 권한 제한, 전송 구간 암호화, 접속 기록 관리, 비정상 이용 탐지, 학생증 이미지 등 인증 자료 접근 최소화 등 개인정보 보호를 위한 기술적·관리적 조치를 시행합니다.',
        ),
        const _Section(
          title: '만 14세 미만 아동',
          body: 'TeenPle은 고등학교 재학생을 주요 대상으로 하며, 만 14세 미만 아동의 회원가입을 허용하지 않습니다.',
        ),
        const _Section(
          title: '자동 수집 장치 및 행태정보',
          body:
              'TeenPle은 현재 웹 쿠키를 통한 개인정보 자동 수집 장치를 운영하지 않습니다.\n\n'
              '또한 현재 맞춤형 광고 제공을 위한 행태정보를 수집·이용하지 않습니다. 다만 서비스 품질 개선과 안정적인 운영을 위해 일반적인 서비스 이용 기록, 접속 기록, 오류 기록 등은 수집될 수 있습니다.',
        ),
        const _Section(
          title: '문의처',
          body:
              '개인정보 관련 문의는 아래 이메일로 접수할 수 있습니다.\n\n'
              'teenple.official@gmail.com',
        ),
        const _Section(
          title: '전체 개인정보처리방침',
          body:
              '본 화면은 개인정보처리방침의 주요 내용을 정리한 것입니다.\n\n'
              '개인정보의 자세한 처리 목적, 처리 항목, 보유 기간, 파기 방법, 제3자 제공, 처리 위탁, 국외 이전, 이용자 권리, 권익침해 구제방법, 변경 이력은 전체 개인정보처리방침에서 확인할 수 있습니다.',
        ),
        TextButton.icon(
          onPressed: onOpenOriginalDocument,
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text('전체 개인정보처리방침 보기'),
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
