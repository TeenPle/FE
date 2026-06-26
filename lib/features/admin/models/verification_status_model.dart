/// 학교 인증 요청 상태 모델
enum VerificationStatusModel { pending, approved, rejected }

extension VerificationStatusModelX on VerificationStatusModel {
  /// 백엔드 요청 파라미터 값
  String get toQueryValue {
    switch (this) {
      case VerificationStatusModel.pending:
        return 'PENDING';
      case VerificationStatusModel.approved:
        return 'APPROVED';
      case VerificationStatusModel.rejected:
        return 'REJECTED';
    }
  }

  /// 화면 표시용 텍스트
  String get label {
    switch (this) {
      case VerificationStatusModel.pending:
        return '승인 요청';
      case VerificationStatusModel.approved:
        return '승인 완료';
      case VerificationStatusModel.rejected:
        return '거절됨';
    }
  }

  /// 백엔드 문자열 -> enum 변환
  static VerificationStatusModel fromJson(String value) {
    switch (value) {
      case 'PENDING':
        return VerificationStatusModel.pending;
      case 'APPROVED':
        return VerificationStatusModel.approved;
      case 'REJECTED':
        return VerificationStatusModel.rejected;
      default:
        return VerificationStatusModel.pending;
    }
  }
}
