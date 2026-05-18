/// 로그인은 시도했지만 학교 인증 상태 때문에
/// 메인 페이지로 바로 보낼 수 없는 경우의 타입
enum LoginBlockedReason {
  /// 학교 인증 승인 대기중
  pending,

  /// 학교 인증 반려됨
  rejected,

  /// 학교 인증 요청 자체가 없음
  required,

  /// 학교 인증 상태가 비정상
  invalid,
}

extension LoginBlockedReasonX on LoginBlockedReason {
  /// 화면 제목
  String get title {
    switch (this) {
      case LoginBlockedReason.pending:
        return '계정 승인중이에요.';
      case LoginBlockedReason.rejected:
        return '학교 인증이 반려되었어요.';
      case LoginBlockedReason.required:
        return '학교 인증이 필요해요.';
      case LoginBlockedReason.invalid:
        return '인증 상태를 확인할 수 없어요.';
    }
  }

  /// 화면 설명
  String get description {
    switch (this) {
      case LoginBlockedReason.pending:
        return '학교 인증이 아직 승인되지 않았어요.\n관리자 확인이 끝날 때까지 조금만 기다려주세요.';
      case LoginBlockedReason.rejected:
        return '제출한 학교 인증 정보가 승인되지 않았어요.\n반려 사유를 확인하고 다시 인증을 요청해주세요.';
      case LoginBlockedReason.required:
        return '학교 인증 정보가 아직 제출되지 않았어요.\n회원가입 후 학교 인증 절차를 완료해주세요.';
      case LoginBlockedReason.invalid:
        return '학교 인증 상태를 확인할 수 없어요.\n잠시 후 다시 시도하거나 관리자에게 문의해주세요.';
    }
  }
}
