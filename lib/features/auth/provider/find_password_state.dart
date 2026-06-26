class FindPasswordState {
  final bool isSendLoading;
  final bool isSendSuccess;
  final String? sendError;

  final bool isVerifyLoading;
  final String? verificationToken;
  final String? verifyError;

  const FindPasswordState({
    this.isSendLoading = false,
    this.isSendSuccess = false,
    this.sendError,
    this.isVerifyLoading = false,
    this.verificationToken,
    this.verifyError,
  });

  bool get isVerified => verificationToken != null;

  FindPasswordState copyWith({
    bool? isSendLoading,
    bool? isSendSuccess,
    String? sendError,
    bool clearSendError = false,
    bool? isVerifyLoading,
    String? verificationToken,
    String? verifyError,
    bool clearVerifyError = false,
    bool clearVerificationToken = false,
  }) {
    return FindPasswordState(
      isSendLoading: isSendLoading ?? this.isSendLoading,
      isSendSuccess: isSendSuccess ?? this.isSendSuccess,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
      isVerifyLoading: isVerifyLoading ?? this.isVerifyLoading,
      verificationToken: clearVerificationToken
          ? null
          : (verificationToken ?? this.verificationToken),
      verifyError: clearVerifyError ? null : (verifyError ?? this.verifyError),
    );
  }
}
