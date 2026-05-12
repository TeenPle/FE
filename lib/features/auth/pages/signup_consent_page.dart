import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_bottom_action_area.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';

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
  static const _termsUrl =
      'https://www.notion.so/7715bdc3bc8c479c859d6716aa4bfeac';
  static const _privacyCollectionConsentUrl =
      'https://www.notion.so/35e4dbb9055f80a8baa4d993a79d0e61';

  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeAge = false;

  bool get _allAgreed => _agreeTerms && _agreePrivacy && _agreeAge;

  /// 이용약관과 개인정보 동의는 사용자가 상세 내용을 확인한 뒤 바텀시트의
  /// "동의함" 버튼을 눌렀을 때만 체크 처리합니다. 체크 아이콘이나 항목
  /// 텍스트를 눌러도 바로 선택되지 않고 항상 상세 확인 흐름으로 진입합니다.
  Future<void> _showLegalAgreementSheet(_LegalAgreementType type) async {
    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LegalAgreementSheet(
        type: type,
        onOpenExternalUrl: () => _openExternalLegalUrl(type.url),
      ),
    );

    if (!mounted || agreed != true) return;

    setState(() {
      if (type == _LegalAgreementType.terms) {
        _agreeTerms = true;
      } else {
        _agreePrivacy = true;
      }
    });
  }

  /// 실제 배포 앱에서 사용자가 전체 원문을 확인할 수 있도록 Notion 문서를
  /// 외부 브라우저/앱으로 엽니다. 앱 내 요약 동의와 별개로, 최신 법적 문서는
  /// 전달받은 고정 URL에서 확인하게 하여 문서 교체 시 앱 심사 영향도 줄입니다.
  Future<void> _openExternalLegalUrl(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('약관 페이지를 열 수 없습니다. 잠시 후 다시 시도해주세요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AuthStepLayout(
      bottom: SizedBox(
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
          child: Text(
            '동의하고 계속하기',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뒤로가기
          IconButton(
            onPressed: () {
              if (context.canPop()) context.pop();
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            splashRadius: 22,
          ),

          SizedBox(height: 24),

          Text(
            '서비스 이용에\n동의해주세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.6,
              color: c.textPrimary,
            ),
          ),

          SizedBox(height: 10),

          Text(
            'TeenPle는 만 15세 이상 고등학교 재학생을 위한 서비스입니다.',
            style: TextStyle(fontSize: 13, height: 1.5, color: c.textBody),
          ),

          SizedBox(height: 32),

          // 개별 항목
          _ConsentItem(
            checked: _agreeTerms,
            label: '[필수] 이용약관',
            onTap: () => _showLegalAgreementSheet(_LegalAgreementType.terms),
          ),

          SizedBox(height: 8),

          _ConsentItem(
            checked: _agreePrivacy,
            label: '[필수] 개인정보 수집·이용 동의',
            onTap: () => _showLegalAgreementSheet(_LegalAgreementType.privacy),
          ),

          SizedBox(height: 8),

          _AgeConsentItem(
            checked: _agreeAge,
            onChanged: (v) => setState(() => _agreeAge = v ?? false),
          ),

          SizedBox(height: 24),

          const _PrivacyNote(),
        ],
      ),
    );
  }
}

// ─── 일반 동의 항목 ───────────────────────────────────────

class _ConsentItem extends StatelessWidget {
  final bool checked;
  final String label;
  final VoidCallback onTap;

  const _ConsentItem({
    required this.checked,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            _CheckCircle(checked: checked),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textBody,
                ),
              ),
            ),
            Text(
              checked ? '다시 보기' : '상세 보기',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A67F2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LegalAgreementType {
  terms,
  privacy;

  String get title {
    switch (this) {
      case _LegalAgreementType.terms:
        return '이용약관';
      case _LegalAgreementType.privacy:
        return '개인정보 수집·이용 동의';
    }
  }

  String get url {
    switch (this) {
      case _LegalAgreementType.terms:
        return _SignupConsentPageState._termsUrl;
      case _LegalAgreementType.privacy:
        return _SignupConsentPageState._privacyCollectionConsentUrl;
    }
  }

  List<_LegalSectionData> get sections {
    switch (this) {
      case _LegalAgreementType.terms:
        return const [
          _LegalSectionData(
            title: '서비스 개요',
            body:
                'TeenPle은 학교 인증을 완료한 고등학생들이 게시글, 댓글, 채팅, 신고, 알림 등을 통해 소통하는 학교 기반 커뮤니티 서비스입니다. 본 약관은 서비스 이용 조건과 회원·운영자의 권리와 의무를 정합니다.',
          ),
          _LegalSectionData(
            title: '가입 및 인증',
            body:
                '서비스는 대한민국 고등학교 재학생 또는 이에 준하는 이용자를 주요 대상으로 합니다. 회원은 본인의 실제 정보로 가입해야 하며, 학교 인증, 학생증 인증, 이메일 인증, 휴대전화 인증 등 필요한 절차를 완료해야 할 수 있습니다.',
          ),
          _LegalSectionData(
            title: '계정 관리',
            body:
                '회원은 본인의 계정과 기기를 안전하게 관리해야 하며, 계정을 타인에게 양도, 대여, 공유해서는 안 됩니다. 허위 가입, 타인 정보 이용, 사칭, 인증 자료 조작, 계정 공유가 확인되면 이용 제한 또는 계정 삭제가 이루어질 수 있습니다.',
          ),
          _LegalSectionData(
            title: '서비스 이용 및 변경',
            body:
                '회원은 본 약관, 운영정책 및 관련 법령을 준수해야 합니다. 운영자는 서비스 개선, 기능 변경, 점검, 장애 대응, 보안 조치, 정책 변경 등의 사유로 서비스의 전부 또는 일부를 변경하거나 일시 중단할 수 있습니다.',
          ),
          _LegalSectionData(
            title: '개인정보 및 청소년 보호',
            body:
                '운영자는 개인정보를 개인정보처리방침에 따라 처리하며, 청소년 유해 정보 차단, 신고 처리, 이용 제한 등 청소년 보호 조치를 시행할 수 있습니다. 회원은 타인의 개인정보, 사진, 연락처, SNS 계정, 위치 정보 등을 동의 없이 게시하거나 유포해서는 안 됩니다.',
          ),
          _LegalSectionData(
            title: '금지 행위',
            body:
                '회원은 학교폭력, 따돌림, 괴롭힘, 협박, 혐오·차별 표현, 특정 학생·교사·학교에 대한 비방이나 허위 사실 유포, 성적 수치심을 유발하는 표현, 불법·유해·광고성 게시물, 도배, 분쟁 유도, 신고 기능 악용, 운영자 또는 회원 사칭, 타인의 권리·명예·사생활 침해 행위를 해서는 안 됩니다.',
          ),
          _LegalSectionData(
            title: '콘텐츠 권리와 관리',
            body:
                '회원이 작성한 게시글, 댓글, 채팅 등 콘텐츠의 권리는 원칙적으로 해당 회원에게 있습니다. 다만 회원은 서비스 내 게시, 노출, 저장, 전송, 검색, 추천, 알림, 신고 처리, 분쟁 대응, 운영정책 집행에 필요한 범위에서 운영자가 콘텐츠를 이용할 수 있도록 허락합니다.',
          ),
          _LegalSectionData(
            title: '신고 및 제재',
            body:
                '회원은 부적절한 콘텐츠 또는 이용자를 신고할 수 있습니다. 운영자는 신고 내용, 이용 기록, 콘텐츠 내용을 검토하여 게시물·댓글·채팅 삭제 또는 임시 숨김, 경고, 일정 기간 이용 제한, 영구 이용 제한, 계정 삭제 등의 조치를 할 수 있습니다. 반복 위반 또는 중대한 위반에는 더 강한 제재가 적용될 수 있습니다.',
          ),
          _LegalSectionData(
            title: '탈퇴 및 복구',
            body:
                '회원은 언제든지 서비스 내 기능을 통해 탈퇴를 요청할 수 있습니다. 탈퇴 요청 후 계정은 7일간 탈퇴 대기 상태가 되며, 대기 기간 동안 복구를 요청할 수 있습니다. 복구가 완료되면 탈퇴 요청은 철회됩니다. 탈퇴 후 개인정보와 콘텐츠 처리 및 보관 기간은 개인정보처리방침 및 운영정책에 따릅니다.',
          ),
          _LegalSectionData(
            title: '책임 및 분쟁 해결',
            body:
                '운영자는 회원이 작성한 콘텐츠의 정확성, 신뢰성, 적법성을 보증하지 않으며, 회원 간 또는 회원과 제3자 간 분쟁은 당사자 간 해결을 원칙으로 합니다. 다만 운영자는 관련 법령과 운영정책에 따라 필요한 조치를 할 수 있으며, 운영자의 고의 또는 중대한 과실로 인한 책임은 관련 법령에 따릅니다.',
          ),
          _LegalSectionData(
            title: '약관 변경 및 시행일',
            body:
                '운영자는 관련 법령을 위반하지 않는 범위에서 약관을 변경할 수 있으며, 변경 내용은 서비스 내 공지사항 또는 별도 안내를 통해 고지합니다. 본 약관은 대한민국 법령에 따라 해석되며, 2026년 5월 8일부터 시행합니다.',
          ),
        ];
      case _LegalAgreementType.privacy:
        return const [
          _LegalSectionData(
            title: '수집·이용 목적',
            body:
                'TeenPle은 회원가입, 학교 인증, 계정 생성, 이메일 인증, 휴대전화번호 확인, 중복 가입 및 부정 이용 방지, 게시글·댓글·채팅·알림·신고 기능 제공, 신고 처리, 분쟁 대응, 청소년 보호, 서비스 보안 관리, 유해 이미지 탐지 및 서비스 품질 개선을 위해 개인정보를 이용합니다.',
          ),
          _LegalSectionData(
            title: '회원가입 시 수집하는 정보',
            body:
                '회원가입 시 이름, 닉네임, 성별, 이메일 주소, 비밀번호, 휴대전화번호, 학교명, 학년을 필수로 수집합니다. 비밀번호는 일방향 암호화 등 안전한 방식으로 저장되며, TeenPle은 비밀번호 원문을 확인할 수 없습니다.',
          ),
          _LegalSectionData(
            title: '학교 인증 및 서비스 이용 정보',
            body:
                '학교 인증을 위해 학생증 인증 이미지, 이미지에 포함된 인증 필요 정보, 인증 상태, 인증 요청 및 처리 일시, 인증 반려 사유를 수집할 수 있습니다. 서비스 이용 과정에서 이용 기록, 로그인 기록, 접속 일시, IP 주소, 기기 정보, OS 정보, 앱 버전 정보, 푸시 알림 토큰, 신고 및 제재 이력, 회원 문의 기록, 게시글·댓글·채팅·이미지·첨부 파일, 유해 이미지 탐지 결과가 생성 또는 수집될 수 있습니다.',
          ),
          _LegalSectionData(
            title: '학생증 인증 안내',
            body:
                '학생증 이미지에는 이름, 학교명, 학년, 사진, 학번, 생년월일 등이 포함될 수 있습니다. 학생증 업로드 시 학교 재학생 여부 확인에 필요하지 않은 정보는 가린 후 제출할 수 있으며, TeenPle은 학교 인증에 필요한 범위에서만 학생증 이미지를 확인합니다.',
          ),
          _LegalSectionData(
            title: '보유 및 이용 기간',
            body:
                '개인정보는 수집·이용 목적이 달성되면 지체 없이 파기합니다. 회원 계정 정보는 탈퇴 완료 시까지 보관하며, 탈퇴 요청 후 7일간은 계정 복구를 위해 탈퇴 대기 상태로 보관됩니다. 정식 탈퇴 완료 후에는 관련 법령 또는 운영정책상 보관이 필요한 정보를 제외하고 파기합니다.',
          ),
          _LegalSectionData(
            title: '인증 이미지와 운영 기록 보관',
            body:
                '학생증 인증 이미지는 학교 인증 승인 또는 거절 처리 완료 시까지 보관하며, 승인 또는 거절 처리 후 지체 없이 삭제합니다. 서비스 이용 기록 및 접속 기록은 부정 이용 방지, 보안 점검, 장애 대응, 분쟁 대응을 위해 최대 1년간 보관될 수 있으며, 신고 및 제재 이력은 반복 위반 방지, 청소년 보호, 분쟁 대응을 위해 처리 완료일 또는 제재 종료일로부터 최대 3년간 보관될 수 있습니다.',
          ),
          _LegalSectionData(
            title: '콘텐츠 및 동의 거부 권리',
            body:
                '게시글, 댓글, 채팅, 이미지 등 회원이 작성하거나 전송한 콘텐츠는 서비스 제공 및 운영에 필요한 기간 동안 보관되며, 탈퇴 시 삭제 또는 익명 처리될 수 있습니다. 회원은 개인정보 수집·이용에 대한 동의를 거부할 수 있으나, 필수 항목에 동의하지 않을 경우 회원가입, 학교 인증 및 서비스 이용이 제한될 수 있습니다.',
          ),
        ];
    }
  }
}

class _LegalAgreementSheet extends StatelessWidget {
  final _LegalAgreementType type;
  final VoidCallback onOpenExternalUrl;

  const _LegalAgreementSheet({
    required this.type,
    required this.onOpenExternalUrl,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.56,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.pageBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        type.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: Icon(Icons.close_rounded, color: c.textBody),
                      splashRadius: 22,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Text(
                      '아래 주요 내용을 확인한 뒤 동의함을 눌러야 회원가입 필수 동의가 완료됩니다. 전체 원문은 하단 링크에서 확인할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final section in type.sections)
                      _LegalSheetSection(section: section),
                    TextButton.icon(
                      onPressed: onOpenExternalUrl,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('전체 문서 자세히 보기'),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        foregroundColor: const Color(0xFF4A67F2),
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        AppHaptics.selection();
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A67F2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '동의함',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegalSectionData {
  final String title;
  final String body;

  const _LegalSectionData({required this.title, required this.body});
}

class _LegalSheetSection extends StatelessWidget {
  final _LegalSectionData section;

  const _LegalSheetSection({required this.section});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            section.body,
            style: TextStyle(fontSize: 12, height: 1.7, color: c.textBody),
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
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onChanged(!checked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CheckCircle(checked: checked),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[필수] 만 14세 이상 확인',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.textBody,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '만 14세 미만은 서비스를 이용할 수 없습니다.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: c.textMuted,
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
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? const Color(0xFF4A67F2) : c.cardBg,
        border: Border.all(
          color: checked ? const Color(0xFF4A67F2) : const Color(0xFFCBD1DB),
          width: 1.5,
        ),
      ),
      child: checked
          ? Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

// ─── 하단 안내 문구 ───────────────────────────────────────

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 11, height: 1.6, color: c.textMuted),
        children: [
          const TextSpan(
            text:
                '동의 후 수집된 개인정보는 서비스 제공 목적으로만 사용됩니다. '
                '자세한 내용은 ',
          ),
          TextSpan(
            text: '개인정보처리방침',
            style: TextStyle(
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
