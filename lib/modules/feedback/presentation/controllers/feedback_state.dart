class FeedbackFormState {
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  const FeedbackFormState({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  FeedbackFormState copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return FeedbackFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
