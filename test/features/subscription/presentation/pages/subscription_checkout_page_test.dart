import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/subscription/domain/entities/active_subscription.dart';
import 'package:quan_oi/features/subscription/presentation/controllers/subscription_notifier.dart';
import 'package:quan_oi/features/subscription/presentation/controllers/subscription_state.dart';
import 'package:quan_oi/features/subscription/presentation/pages/subscription_checkout_page.dart';
import 'package:quan_oi/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  testWidgets('checkout page pops when subscription becomes active', (
    tester,
  ) async {
    final notifier = _CheckoutTestSubscriptionNotifier(
      const SubscriptionState(status: SubscriptionStatus.waitingForPayment),
    );
    final observer = _PopCountingNavigatorObserver();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionNotifierProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const _CheckoutTestHost(),
        ),
      ),
    );

    await tester.tap(find.text('Open checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Fake PayOS WebView'), findsOneWidget);

    notifier.emit(
      const SubscriptionState(
        status: SubscriptionStatus.ready,
        activeSubscription: _activeSubscription,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fake PayOS WebView'), findsNothing);
    expect(find.text('Checkout host'), findsOneWidget);
    expect(
      find.text('Thanh toán thành công, gói dịch vụ đã được kích hoạt'),
      findsOneWidget,
    );
    expect(observer.popCount, 1);

    notifier.emit(
      const SubscriptionState(
        status: SubscriptionStatus.ready,
        activeSubscription: _activeSubscription,
      ),
    );
    await tester.pumpAndSettle();

    expect(observer.popCount, 1);
  });

  testWidgets('checkout page pops when payment fails', (tester) async {
    final notifier = _CheckoutTestSubscriptionNotifier(
      const SubscriptionState(status: SubscriptionStatus.waitingForPayment),
    );
    final observer = _PopCountingNavigatorObserver();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionNotifierProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const _CheckoutTestHost(),
        ),
      ),
    );

    await tester.tap(find.text('Open checkout'));
    await tester.pumpAndSettle();

    notifier.emit(
      const SubscriptionState(status: SubscriptionStatus.paymentFailed),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fake PayOS WebView'), findsNothing);
    expect(find.text('Thanh toán gói dịch vụ thất bại'), findsOneWidget);
    expect(observer.popCount, 1);
  });
}

class _CheckoutTestHost extends StatelessWidget {
  const _CheckoutTestHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Checkout host'),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SubscriptionCheckoutPage(
                      paymentLink: 'https://pay.payos.vn/web/test',
                      webViewForTesting: Center(
                        child: Text('Fake PayOS WebView'),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutTestSubscriptionNotifier extends SubscriptionNotifier {
  final SubscriptionState _initialState;

  _CheckoutTestSubscriptionNotifier(this._initialState);

  @override
  SubscriptionState build() {
    return _initialState;
  }

  void emit(SubscriptionState value) {
    state = value;
  }
}

class _PopCountingNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount += 1;
    super.didPop(route, previousRoute);
  }
}

const _activeSubscription = ActiveSubscription(
  id: 12,
  accountId: 20,
  planId: 1,
  planName: 'Basic',
  price: 10000,
  startDate: null,
  endDate: null,
  daysRemaining: 29,
  isActive: true,
  isExpired: false,
  maxStores: 1,
  maxUsers: 5,
  status: 'Active',
  autoRenew: true,
  cancelAt: null,
);
