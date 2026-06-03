import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_event_names.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../domain/entities/active_subscription.dart';
import '../../domain/entities/payment_status_changed_payload.dart';
import '../../domain/entities/pending_subscription_purchase.dart';
import '../../domain/entities/service_package.dart';
import '../providers/subscription_providers.dart';
import 'subscription_state.dart';

class SubscriptionNotifier extends AutoDisposeNotifier<SubscriptionState> {
  static const _returnUrl = 'quanoi://subscription/success';
  static const _cancelUrl = 'quanoi://subscription/cancel';
  static const _pollInterval = Duration(seconds: 3);
  static const _maxPollAttempts = 10;

  bool _initialLoadStarted = false;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  final Set<int> _processedPaymentIds = <int>{};

  @override
  SubscriptionState build() {
    ref.listen(realtimeNotificationStreamProvider, (previous, next) {
      final message = next.valueOrNull;
      if (message == null ||
          message.eventName != RealtimeEventNames.paymentStatusChanged) {
        return;
      }

      try {
        final payload = PaymentStatusChangedPayload.fromJson(message.payload);
        debugPrint(
          'Subscription realtime payment.status.changed: '
          'paymentId=${payload.paymentId}, '
          'paymentStatus=${payload.paymentStatus}, '
          'subscriptionStatus=${payload.subscriptionStatus}',
        );
        unawaited(handlePaymentStatusChanged(payload));
      } on FormatException {
        return;
      }
    });

    ref.onDispose(_stopPolling);
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
      clearActiveSubscription: true,
      clearPurchasingPlanId: true,
      clearCheckoutUrl: true,
    );

    try {
      final loadPlansUseCase = ref.read(loadSubscriptionPlansUseCaseProvider);
      final loadActiveSubscriptionUseCase = ref.read(
        loadActiveSubscriptionUseCaseProvider,
      );
      final loadPendingPurchaseUseCase = ref.read(
        loadPendingSubscriptionPurchaseUseCaseProvider,
      );
      final plansFuture = loadPlansUseCase();
      final activeSubscriptionFuture = loadActiveSubscriptionUseCase();
      final pendingPurchaseFuture = loadPendingPurchaseUseCase();
      final results = await Future.wait<Object?>([
        plansFuture,
        activeSubscriptionFuture,
        pendingPurchaseFuture,
      ]);
      final plans = results[0] as List<ServicePackage>;
      final activeSubscription = results[1] as ActiveSubscription?;
      final pendingPurchase = results[2] as PendingSubscriptionPurchase?;
      final hasActiveSubscription = _isActiveSubscription(activeSubscription);
      state = SubscriptionState(
        status: hasActiveSubscription
            ? SubscriptionStatus.ready
            : pendingPurchase == null
            ? SubscriptionStatus.ready
            : SubscriptionStatus.waitingForPayment,
        plans: plans,
        activeSubscription: activeSubscription,
        pendingPurchase: hasActiveSubscription ? null : pendingPurchase,
      );

      if (hasActiveSubscription && pendingPurchase != null) {
        await ref.read(clearPendingSubscriptionPurchaseUseCaseProvider)();
      } else if (pendingPurchase != null) {
        _startPolling();
      }
    } catch (error) {
      state = SubscriptionState(
        status: SubscriptionStatus.error,
        plans: state.plans,
        activeSubscription: state.activeSubscription,
        pendingPurchase: state.pendingPurchase,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> purchasePlan(ServicePackage plan) async {
    if (!plan.isActive) {
      return;
    }

    if (_hasDifferentActivePlan(plan)) {
      state = state.copyWith(
        status: SubscriptionStatus.error,
        errorMessage:
            'Bạn đang sử dụng gói khác. Vui lòng hủy gói hiện tại trước khi mua gói khác.',
      );
      return;
    }

    final planId = int.tryParse(plan.id);
    if (planId == null) {
      state = state.copyWith(
        status: SubscriptionStatus.error,
        errorMessage: 'Gói dịch vụ không hợp lệ',
      );
      return;
    }

    _stopPolling();
    state = state.copyWith(
      status: SubscriptionStatus.purchasing,
      purchasingPlanId: plan.id,
      clearError: true,
      clearCheckoutUrl: true,
    );

    try {
      final purchaseUseCase = ref.read(purchaseSubscriptionUseCaseProvider);
      final result = await purchaseUseCase(
        planId: planId,
        autoRenew: true,
        returnUrl: _returnUrl,
        cancelUrl: _cancelUrl,
      );
      final pendingPurchase = result.toPendingPurchase();

      state = state.copyWith(
        status: SubscriptionStatus.waitingForPayment,
        pendingPurchase: pendingPurchase,
        checkoutUrl: pendingPurchase.paymentLink,
        clearError: true,
        clearPurchasingPlanId: true,
      );
      _startPolling();
    } catch (error) {
      final message = _cleanError(error);
      if (message.contains('giao dịch mua gói đang chờ thanh toán')) {
        final pendingPurchase = await ref
            .read(loadPendingSubscriptionPurchaseUseCaseProvider)
            .call();
        state = state.copyWith(
          status: pendingPurchase == null
              ? SubscriptionStatus.error
              : SubscriptionStatus.waitingForPayment,
          pendingPurchase: pendingPurchase,
          errorMessage: pendingPurchase == null ? message : null,
          clearError: pendingPurchase != null,
          clearPurchasingPlanId: true,
        );
        if (pendingPurchase != null) {
          _startPolling();
        }
        return;
      }

      state = state.copyWith(
        status: SubscriptionStatus.error,
        errorMessage: message,
        clearPurchasingPlanId: true,
      );
    }
  }

  void markCheckoutOpened() {
    if (state.checkoutUrl != null) {
      state = state.copyWith(clearCheckoutUrl: true);
    }
  }

  void continuePendingPayment() {
    final pendingPurchase = state.pendingPurchase;
    if (pendingPurchase == null || pendingPurchase.paymentLink.isEmpty) {
      return;
    }

    state = state.copyWith(
      status: SubscriptionStatus.waitingForPayment,
      checkoutUrl: pendingPurchase.paymentLink,
      clearError: true,
    );
    _startPolling();
  }

  Future<void> refreshAfterPaymentReturn() async {
    await _refreshActiveSubscription(
      refreshingStatus: SubscriptionStatus.waitingForPayment,
      keepWaitingWhenInactive: true,
    );

    if (!_isActiveSubscription(state.activeSubscription) &&
        state.pendingPurchase != null) {
      _startPolling();
    }
  }

  Future<void> handlePaymentStatusChanged(
    PaymentStatusChangedPayload payload,
  ) async {
    if (!payload.isSubscriptionPayment) {
      return;
    }

    if (!_processedPaymentIds.add(payload.paymentId)) {
      return;
    }

    if (payload.isCompletedActive) {
      await _refreshActiveSubscription(
        refreshingStatus: SubscriptionStatus.paymentCompletedRefreshing,
        keepWaitingWhenInactive: false,
      );
      return;
    }

    if (payload.isFailed) {
      _stopPolling();
      await _refreshActiveSubscription(
        refreshingStatus: SubscriptionStatus.paymentFailed,
        keepWaitingWhenInactive: true,
      );
      state = state.copyWith(status: SubscriptionStatus.paymentFailed);
    }
  }

  Future<void> _refreshActiveSubscription({
    required SubscriptionStatus refreshingStatus,
    required bool keepWaitingWhenInactive,
  }) async {
    state = state.copyWith(status: refreshingStatus, clearError: true);

    try {
      final loadActiveSubscriptionUseCase = ref.read(
        loadActiveSubscriptionUseCaseProvider,
      );
      final activeSubscription = await loadActiveSubscriptionUseCase();

      if (_isActiveSubscription(activeSubscription)) {
        _stopPolling();
        await ref.read(clearPendingSubscriptionPurchaseUseCaseProvider)();
        state = state.copyWith(
          status: SubscriptionStatus.ready,
          activeSubscription: activeSubscription,
          clearPendingPurchase: true,
          clearCheckoutUrl: true,
          clearError: true,
        );
        return;
      }

      state = state.copyWith(
        status: keepWaitingWhenInactive
            ? SubscriptionStatus.waitingForPayment
            : SubscriptionStatus.ready,
        clearActiveSubscription: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: SubscriptionStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void _startPolling() {
    if (_pollTimer != null || state.pendingPurchase == null) {
      return;
    }

    _pollAttempts = 0;
    _pollTimer = Timer.periodic(_pollInterval, (timer) {
      _pollAttempts += 1;
      if (_pollAttempts > _maxPollAttempts) {
        _stopPolling();
        return;
      }

      unawaited(
        _refreshActiveSubscription(
          refreshingStatus: SubscriptionStatus.waitingForPayment,
          keepWaitingWhenInactive: true,
        ),
      );
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollAttempts = 0;
  }

  bool _hasDifferentActivePlan(ServicePackage plan) {
    final activeSubscription = state.activeSubscription;
    return activeSubscription != null &&
        _isActiveSubscription(activeSubscription) &&
        activeSubscription.planId.toString() != plan.id;
  }

  bool _isActiveSubscription(ActiveSubscription? subscription) {
    return subscription != null &&
        subscription.isActive &&
        !subscription.isExpired &&
        subscription.status == 'Active';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
