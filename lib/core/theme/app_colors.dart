import 'package:flutter/material.dart';

/// 앱 전체 시맨틱 색상 토큰.
/// ThemeExtension으로 등록해 라이트/다크 테마에서 자동 전환됩니다.
class AppColors extends ThemeExtension<AppColors> {
  // ── 배경 ────────────────────────────────────────────────
  final Color pageBg; // 스캐폴드 / 페이지 배경
  final Color cardBg; // 카드 / 흰 서피스
  final Color inputBg; // 텍스트 필드 배경
  final Color subtleBg; // 연한 틴티드 서피스 (F8FCFF 계열)
  final Color chipContainerBg; // 세그먼트 컨트롤 / 탭 배경 (EBF2F9 계열)
  final Color tintBg; // 파랑 틴티드 서피스 (EAF7FF 계열)
  final Color replyBg; // 대댓글 배경 (EAF5FF 계열)
  final Color highlightBg; // 답글 대상 하이라이트 (DFF0FF 계열)

  // ── 텍스트 ───────────────────────────────────────────────
  final Color textPrimary; // 제목 / 주요 텍스트
  final Color textBody; // 본문 텍스트 (2F3740 계열)
  final Color textSecondary; // 설명 / 서브 텍스트 (59616C 계열)
  final Color textTertiary; // 메타 / 타임스탬프 (9AA7B2 계열)
  final Color textMuted; // 힌트에 가까운 텍스트 (7D8790 계열)
  final Color textHint; // 입력 placeholder (B3B3B3 계열)
  final Color textDisabled; // 비활성 / 빈 상태 안내 (C0D4E4 계열)

  // ── 테두리 / 구분선 ──────────────────────────────────────
  final Color border; // 카드 기본 테두리 (E1ECF5 계열)
  final Color borderStrong; // 좀 더 짙은 테두리 (E6EDF3 계열)
  final Color borderSubtle; // 디바이더 / 인너 구분선 (F0F4F8 계열)
  final Color borderBlue; // 파란 틴티드 테두리 (D6EAFF 계열)
  final Color divider; // 리스트 구분선 (D5DDE6 계열)
  final Color dividerBlue; // 파란 구분선 (DDEAF6 계열)

  // ── 아이콘 ───────────────────────────────────────────────
  final Color iconPrimary; // 헤더 / 주요 아이콘 (0B0B0B 계열)
  final Color iconSecondary; // 보조 아이콘 (9AA7B2 계열)
  final Color iconMuted; // 통계 아이콘 (ABB5BF 계열)
  final Color iconOnCard; // 카드 내부 회색 아이콘 (6E7B87 계열)

  // ── 팝업 / 바텀시트 ──────────────────────────────────────
  final Color popupBg; // PopupMenu / BottomSheet 배경

  const AppColors({
    required this.pageBg,
    required this.cardBg,
    required this.inputBg,
    required this.subtleBg,
    required this.chipContainerBg,
    required this.tintBg,
    required this.replyBg,
    required this.highlightBg,
    required this.textPrimary,
    required this.textBody,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMuted,
    required this.textHint,
    required this.textDisabled,
    required this.border,
    required this.borderStrong,
    required this.borderSubtle,
    required this.borderBlue,
    required this.divider,
    required this.dividerBlue,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconMuted,
    required this.iconOnCard,
    required this.popupBg,
  });

  // ── 라이트 토큰 (기존 하드코딩 값과 1:1 동일) ────────────
  factory AppColors.light() => const AppColors(
    pageBg: Color(0xFFF6FBFF),
    cardBg: Color(0xFFFFFFFF),
    inputBg: Color(0xFFF5F5F5),
    subtleBg: Color(0xFFF8FCFF),
    chipContainerBg: Color(0xFFEBF2F9),
    tintBg: Color(0xFFEAF7FF),
    replyBg: Color(0xFFEAF5FF),
    highlightBg: Color(0xFFDFF0FF),
    textPrimary: Color(0xFF111111),
    textBody: Color(0xFF2F3740),
    textSecondary: Color(0xFF59616C),
    textTertiary: Color(0xFF9AA7B2),
    textMuted: Color(0xFF7D8790),
    textHint: Color(0xFFB3B3B3),
    textDisabled: Color(0xFFC0D4E4),
    border: Color(0xFFE1ECF5),
    borderStrong: Color(0xFFE6EDF3),
    borderSubtle: Color(0xFFF0F4F8),
    borderBlue: Color(0xFFD6EAFF),
    divider: Color(0xFFD5DDE6),
    dividerBlue: Color(0xFFDDEAF6),
    iconPrimary: Color(0xFF0B0B0B),
    iconSecondary: Color(0xFF9AA7B2),
    iconMuted: Color(0xFFABB5BF),
    iconOnCard: Color(0xFF6E7B87),
    popupBg: Color(0xFFFFFFFF),
  );

  // ── 다크 토큰 ────────────────────────────────────────────
  factory AppColors.dark() => const AppColors(
    pageBg: Color(0xFF111318),
    cardBg: Color(0xFF1C2028),
    inputBg: Color(0xFF1E2530),
    subtleBg: Color(0xFF161E28),
    chipContainerBg: Color(0xFF1A2230),
    tintBg: Color(0xFF152240),
    replyBg: Color(0xFF162236),
    highlightBg: Color(0xFF1A3050),
    textPrimary: Color(0xFFE4EAF0),
    textBody: Color(0xFFCDD5DF),
    textSecondary: Color(0xFF8A96A4),
    textTertiary: Color(0xFF505E6E),
    textMuted: Color(0xFF6A7888),
    textHint: Color(0xFF3A4A58),
    textDisabled: Color(0xFF2A3A48),
    border: Color(0xFF252D3A),
    borderStrong: Color(0xFF262E3C),
    borderSubtle: Color(0xFF1E2630),
    borderBlue: Color(0xFF1E3550),
    divider: Color(0xFF252D3A),
    dividerBlue: Color(0xFF1E2E40),
    iconPrimary: Color(0xFFD0D8E4),
    iconSecondary: Color(0xFF505E6E),
    iconMuted: Color(0xFF404E5E),
    iconOnCard: Color(0xFF6A7888),
    popupBg: Color(0xFF252D3A),
  );

  @override
  AppColors copyWith({
    Color? pageBg,
    Color? cardBg,
    Color? inputBg,
    Color? subtleBg,
    Color? chipContainerBg,
    Color? tintBg,
    Color? replyBg,
    Color? highlightBg,
    Color? textPrimary,
    Color? textBody,
    Color? textSecondary,
    Color? textTertiary,
    Color? textMuted,
    Color? textHint,
    Color? textDisabled,
    Color? border,
    Color? borderStrong,
    Color? borderSubtle,
    Color? borderBlue,
    Color? divider,
    Color? dividerBlue,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? iconMuted,
    Color? iconOnCard,
    Color? popupBg,
  }) {
    return AppColors(
      pageBg: pageBg ?? this.pageBg,
      cardBg: cardBg ?? this.cardBg,
      inputBg: inputBg ?? this.inputBg,
      subtleBg: subtleBg ?? this.subtleBg,
      chipContainerBg: chipContainerBg ?? this.chipContainerBg,
      tintBg: tintBg ?? this.tintBg,
      replyBg: replyBg ?? this.replyBg,
      highlightBg: highlightBg ?? this.highlightBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textBody: textBody ?? this.textBody,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textMuted: textMuted ?? this.textMuted,
      textHint: textHint ?? this.textHint,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderBlue: borderBlue ?? this.borderBlue,
      divider: divider ?? this.divider,
      dividerBlue: dividerBlue ?? this.dividerBlue,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      iconMuted: iconMuted ?? this.iconMuted,
      iconOnCard: iconOnCard ?? this.iconOnCard,
      popupBg: popupBg ?? this.popupBg,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      pageBg: Color.lerp(pageBg, other.pageBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      subtleBg: Color.lerp(subtleBg, other.subtleBg, t)!,
      chipContainerBg: Color.lerp(chipContainerBg, other.chipContainerBg, t)!,
      tintBg: Color.lerp(tintBg, other.tintBg, t)!,
      replyBg: Color.lerp(replyBg, other.replyBg, t)!,
      highlightBg: Color.lerp(highlightBg, other.highlightBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderBlue: Color.lerp(borderBlue, other.borderBlue, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      dividerBlue: Color.lerp(dividerBlue, other.dividerBlue, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      iconOnCard: Color.lerp(iconOnCard, other.iconOnCard, t)!,
      popupBg: Color.lerp(popupBg, other.popupBg, t)!,
    );
  }
}

/// `context.colors`로 어디서든 접근
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
