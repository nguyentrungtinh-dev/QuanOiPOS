import '../../domain/entities/service_package.dart';

enum SubscriptionStatus { initial, loading, ready, error }

class SubscriptionState {
  final SubscriptionStatus status;
  final List<ServicePackage> plans;
  final String? errorMessage;

  const SubscriptionState({
    required this.status,
    this.plans = const [],
    this.errorMessage,
  });

  const SubscriptionState.initial()
    : status = SubscriptionStatus.initial,
      plans = const [],
      errorMessage = null;

  bool get isLoading => status == SubscriptionStatus.loading;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    List<ServicePackage>? plans,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
