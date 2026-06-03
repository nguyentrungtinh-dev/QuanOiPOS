import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/index.dart';
import '../controllers/subscription_state.dart';
import '../providers/subscription_providers.dart';

class SubscriptionCheckoutPage extends ConsumerStatefulWidget {
  final String paymentLink;
  final Widget? webViewForTesting;

  const SubscriptionCheckoutPage({
    super.key,
    required this.paymentLink,
    this.webViewForTesting,
  });

  @override
  ConsumerState<SubscriptionCheckoutPage> createState() =>
      _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState
    extends ConsumerState<SubscriptionCheckoutPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasClosedCheckout = false;

  @override
  void initState() {
    super.initState();
    if (widget.webViewForTesting != null) {
      _isLoading = false;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: _handleNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentLink));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(subscriptionNotifierProvider, (previous, next) {
      if (_hasClosedCheckout) {
        return;
      }

      if (_isActiveSubscription(next)) {
        _closeCheckout(
          message: 'Thanh toán thành công, gói dịch vụ đã được kích hoạt',
          logMessage:
              'Subscription checkout auto closed after active subscription',
        );
        return;
      }

      if (next.status == SubscriptionStatus.paymentFailed) {
        _closeCheckout(
          message: 'Thanh toán gói dịch vụ thất bại',
          logMessage: 'Subscription checkout closed after failed payment',
        );
      }
    });

    final webView = widget.webViewForTesting;
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán gói dịch vụ')),
      body: Stack(
        children: [
          if (webView != null)
            webView
          else if (controller != null)
            WebViewWidget(controller: controller),
          if (_isLoading)
            const ColoredBox(
              color: AppColors.background,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri != null && uri.scheme == 'quanoi' && uri.host == 'subscription') {
      unawaited(
        ref
            .read(subscriptionNotifierProvider.notifier)
            .refreshAfterPaymentReturn(),
      );
      Navigator.of(context).maybePop();
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  bool _isActiveSubscription(SubscriptionState state) {
    final subscription = state.activeSubscription;
    return subscription != null &&
        subscription.isActive &&
        !subscription.isExpired &&
        subscription.status == 'Active';
  }

  void _closeCheckout({required String message, required String logMessage}) {
    _hasClosedCheckout = true;
    debugPrint(logMessage);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).maybePop();
  }
}
