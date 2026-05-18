class FindEmailState {
  final bool isLoading;
  final String? maskedEmail;
  final String? errorMessage;

  const FindEmailState({
    this.isLoading = false,
    this.maskedEmail,
    this.errorMessage,
  });

  FindEmailState copyWith({
    bool? isLoading,
    String? maskedEmail,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearMaskedEmail = false,
  }) {
    return FindEmailState(
      isLoading: isLoading ?? this.isLoading,
      maskedEmail: clearMaskedEmail ? null : (maskedEmail ?? this.maskedEmail),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
