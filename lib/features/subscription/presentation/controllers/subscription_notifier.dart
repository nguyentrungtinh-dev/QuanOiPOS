import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscription_providers.dart';
import 'subscription_state.dart';

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  bool _initialLoadStarted = false;

  @override
  SubscriptionState build() {
    Future.microtask(loadPlans);
    return const SubscriptionState.initial();
  }

  Future<void> loadPlans() async {
    if (_initialLoadStarted && state.status == SubscriptionStatus.loading) {
      return;
    }

    _initialLoadStarted = true;
    state = state.copyWith(
      status: SubscriptionStatus.loading,
      clearError: true,
    );

    try {
      final useCase = ref.read(loadSubscriptionPlansUseCaseProvider);
      final plans = await useCase();
      state = SubscriptionState(status: SubscriptionStatus.ready, plans: plans);
    } catch (error) {
      state = SubscriptionState(
        status: SubscriptionStatus.error,
        plans: state.plans,
        errorMessage: _cleanError(error),
      );
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
