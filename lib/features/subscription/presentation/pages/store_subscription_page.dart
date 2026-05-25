import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../domain/entities/service_package.dart';
import '../controllers/subscription_state.dart';
import '../providers/subscription_providers.dart';

class StoreSubscriptionPage extends ConsumerWidget {
  const StoreSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gói dịch vụ của tôi')),
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: switch (state.status) {
            SubscriptionStatus.initial || SubscriptionStatus.loading
                when state.plans.isEmpty =>
              const _LoadingView(),
            SubscriptionStatus.error when state.plans.isEmpty => _ErrorView(
              message: state.errorMessage ?? 'Không thể tải gói dịch vụ',
              onRetry: () =>
                  ref.read(subscriptionNotifierProvider.notifier).loadPlans(),
            ),
            _ => _SubscriptionContent(
              state: state,
              onRetry: () =>
                  ref.read(subscriptionNotifierProvider.notifier).loadPlans(),
            ),
          },
        ),
      ),
    );
  }
}

class _SubscriptionContent extends StatelessWidget {
  final SubscriptionState state;
  final Future<void> Function() onRetry;

  const _SubscriptionContent({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Gói dịch vụ hệ thống', style: AppTextStyles.h3),
              ),
              IconButton(
                tooltip: 'Tải lại',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
              ),
            ],
          ),
         
          const SizedBox(height: AppConstants.spacingMd),
          if (state.plans.isEmpty)
            const Expanded(child: Center(child: _EmptyPackagesView()))
          else
            Expanded(child: _SubscriptionPlanCarousel(plans: state.plans)),
        ],
      ),
    );
  }
}

class _SubscriptionPlanCarousel extends StatefulWidget {
  final List<ServicePackage> plans;

  const _SubscriptionPlanCarousel({required this.plans});

  @override
  State<_SubscriptionPlanCarousel> createState() =>
      _SubscriptionPlanCarouselState();
}

class _SubscriptionPlanCarouselState extends State<_SubscriptionPlanCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void didUpdateWidget(covariant _SubscriptionPlanCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.plans.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: const Key('subscription_plan_page_view'),
            controller: _pageController,
            itemCount: widget.plans.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXs,
                ),
                child: _ServicePackageCard(package: widget.plans[index]),
              );
            },
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _CarouselIndicator(
          itemCount: widget.plans.length,
          currentIndex: _currentPage,
        ),
      ],
    );
  }
}

class _CarouselIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const _CarouselIndicator({
    required this.itemCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: AppConstants.animFast,
          width: isActive ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingXs,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.borderStrong,
            borderRadius: BorderRadius.circular(AppConstants.spacingSm),
          ),
        );
      }),
    );
  }
}

class _ServicePackageCard extends StatefulWidget {
  final ServicePackage package;

  const _ServicePackageCard({required this.package});

  @override
  State<_ServicePackageCard> createState() => _ServicePackageCardState();
}

class _ServicePackageCardState extends State<_ServicePackageCard> {
  static const _collapsedFeatureCount = 4;

  bool _showAllFeatures = false;

  ServicePackage get package => widget.package;

  @override
  Widget build(BuildContext context) {
    final visibleFeatures =
        _showAllFeatures || package.features.length <= _collapsedFeatureCount
        ? package.features
        : package.features.take(_collapsedFeatureCount).toList();
    final canToggleFeatures = package.features.length > _collapsedFeatureCount;

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: AppTextStyles.h1.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                _PlanBadge(package: package),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Center(
              child: Text.rich(
                TextSpan(
                  text: _priceLabel(package),
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: _periodLabel(package),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            const Divider(height: 1),
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: _PlanLimitTile(
                    icon: Icons.storefront_outlined,
                    label: _limitLabel(package.maxStores, 'cửa hàng'),
                    helper: 'Cửa hàng',
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: _PlanLimitTile(
                    icon: Icons.groups_outlined,
                    label: _limitLabel(package.maxUsers, 'người dùng'),
                    helper: 'Người dùng',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),
            const Divider(height: 1),
            if (package.features.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingLg),
              ...visibleFeatures.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.spacingMd,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 15,
                          color: AppColors.surface,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTextStyles.bodyBase.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (canToggleFeatures)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _showAllFeatures = !_showAllFeatures),
                    child: Text(_showAllFeatures ? 'Thu gọn' : 'Xem thêm'),
                  ),
                ),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: package.isActive
                    ? () => _showComingSoon(context)
                    : null,
                child: const Text('MUA GÓI'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _priceLabel(ServicePackage package) {
    if (package.priceAmount <= 0) {
      return 'Miễn phí';
    }

    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(package.priceAmount);
  }

  static String _periodLabel(ServicePackage package) {
    if (package.priceAmount <= 0) {
      return '';
    }

    if (package.durationDays == 30) {
      return '/tháng';
    }

    return '/${package.durationDays} ngày';
  }

  static String _limitLabel(int value, String unit) {
    if (value >= 999) {
      return 'Không giới hạn $unit';
    }

    return '$value $unit';
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng mua gói sẽ được triển khai sau')),
    );
  }
}

class _PlanLimitTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String helper;

  const _PlanLimitTile({
    required this.icon,
    required this.label,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppConstants.spacingSm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: AppColors.textPrimary),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            label,
            style: AppTextStyles.labelSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            helper,
            style: AppTextStyles.bodyXs,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final ServicePackage package;

  const _PlanBadge({required this.package});

  @override
  Widget build(BuildContext context) {
    final isRecommended = package.name.toLowerCase() == 'pro';
    final label = isRecommended
        ? 'Khuyên dùng'
        : (package.isActive ? 'Đang mở bán' : 'Tạm dừng');
    final backgroundColor = isRecommended || package.isActive
        ? AppColors.primary
        : AppColors.muted;
    final foregroundColor = isRecommended || package.isActive
        ? AppColors.surface
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.spacingSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelXs.copyWith(color: foregroundColor),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPackagesView extends StatelessWidget {
  const _EmptyPackagesView();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 40),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Chưa có gói dịch vụ khả dụng',
              style: AppTextStyles.labelSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Vui lòng quay lại sau hoặc liên hệ quản trị hệ thống.',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
