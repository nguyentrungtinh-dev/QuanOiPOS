enum ForgotPasswordStep { email, reset }

enum ForgotPasswordStatus {
  idle,
  submittingEmail,
  awaitingReset,
  confirming,
  success,
  failure,
}

class ForgotPasswordState {
  final ForgotPasswordStep step;
  final ForgotPasswordStatus status;
  final String? email;
  final String? errorMessage;

  const ForgotPasswordState({
    required this.step,
    required this.status,
    this.email,
    this.errorMessage,
  });

  const ForgotPasswordState.initial()
    : step = ForgotPasswordStep.email,
      status = ForgotPasswordStatus.idle,
      email = null,
      errorMessage = null;

  bool get isLoading {
    return status == ForgotPasswordStatus.submittingEmail ||
        status == ForgotPasswordStatus.confirming;
  }

  bool get isAwaitingReset => step == ForgotPasswordStep.reset;

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    ForgotPasswordStatus? status,
    String? email,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
