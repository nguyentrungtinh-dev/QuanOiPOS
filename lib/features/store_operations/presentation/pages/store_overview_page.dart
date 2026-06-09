import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_permission_codes.dart';
import '../../../../core/theme/index.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../widgets/store_bottom_navigation_bar.dart';
import '../widgets/store_workspace_drawer.dart';
import '../widgets/store_workspace_header.dart';

class StoreOverviewPage extends ConsumerWidget {
  final int storeId;

  const StoreOverviewPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeAccessNotifierProvider(storeId));
    final accessContext = state.context;

    return Scaffold(
      drawer: state.status == StoreAccessStatus.ready && accessContext != null
          ? StoreWorkspaceDrawer(activeStoreId: accessContext.store.id)
          : null,
      body: SafeArea(
        bottom: false,
        child: switch (state.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message:
                state.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
          ),
          StoreAccessStatus.error => _ErrorView(
            message: state.errorMessage ?? 'Không thể tải thông tin cửa hàng',
            onRetry: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
            onBackToStores: () => context.goNamed(RouteNames.myStores),
          ),
          StoreAccessStatus.ready => _ReadyView(state: state),
        },
      ),
      bottomNavigationBar:
          state.status == StoreAccessStatus.ready &&
              state.can(AppPermissionCodes.dashboardView)
          ? StoreBottomNavigationBar(
              items: [
                const StoreBottomNavItemData(
                  title: 'Tổng quan',
                  icon: Icons.home_rounded,
                  isActive: true,
                  isEnabled: true,
                ),
                StoreBottomNavItemData(
                  title: 'Bán hàng',
                  icon: Icons.shopping_cart_outlined,
                  onTap: () => _showComingSoon(context, 'Bán hàng'),
                ),
                StoreBottomNavItemData(
                  title: 'Đơn hàng',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => _showComingSoon(context, 'Đơn hàng'),
                ),
                StoreBottomNavItemData(
                  title: 'Sản phẩm',
                  icon: Icons.inventory_2_outlined,
                  isEnabled: state.can(AppPermissionCodes.productView),
                  onTap: () => context.goNamed(
                    RouteNames.storeProductManagement,
                    pathParameters: {'storeId': storeId.toString()},
                  ),
                ),
                StoreBottomNavItemData(
                  title: 'Thêm',
                  icon: Icons.more_horiz,
                  onTap: () => _showComingSoon(context, 'Thêm'),
                ),
              ],
            )
          : null,
    );
  }
}

class _ReadyView extends ConsumerWidget {
  final StoreAccessState state;

  const _ReadyView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessContext = state.context;
    if (accessContext == null) {
      return const _BlockedView(
        icon: Icons.storefront_outlined,
        title: 'Chưa có dữ liệu cửa hàng',
        message: 'Vui lòng quay lại danh sách cửa hàng và thử lại.',
      );
    }

    if (!state.can(AppPermissionCodes.dashboardView)) {
      return const _BlockedView(
        icon: Icons.visibility_off_outlined,
        title: 'Bạn chưa có quyền xem tổng quan',
        message: 'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
      );
    }

    final authState = ref.watch(authNotifierProvider);
    final greetingTarget = authState.fullName ?? authState.email ?? 'bạn';

    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: () => ref
            .read(storeAccessNotifierProvider(accessContext.store.id).notifier)
            .loadAccess(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spacingMd,
            AppConstants.spacingMd,
            AppConstants.spacingMd,
            AppConstants.spacingXxl,
          ),
          children: [
            Builder(
              builder: (context) {
                final headerSubtitle = accessContext.store.address.isEmpty
                    ? 'Chào $greetingTarget'
                    : accessContext.store.address;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StoreWorkspaceHeader(
                      onLogoTap: () => Scaffold.of(context).openDrawer(),
                      onSearchTap: () => context.goNamed(
                        RouteNames.storeFeatureSearch,
                        pathParameters: {
                          'storeId': accessContext.store.id.toString(),
                        },
                      ),
                      onScanTap: () => _showComingSoon(context, 'Quét mã'),
                      onNotificationTap: () =>
                          _showComingSoon(context, 'Thông báo'),
                    ),
                    StoreWorkspaceHeaderTitle(
                      store: accessContext.store,
                      subtitle: headerSubtitle,
                    ),
                  ],
                );
              },
            ),
            if (state.isRefreshing) ...[
              const SizedBox(height: AppConstants.spacingSm),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (state.refreshErrorMessage != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              _RefreshErrorBanner(
                message: state.refreshErrorMessage!,
                onRetry: () => ref
                    .read(
                      storeAccessNotifierProvider(
                        accessContext.store.id,
                      ).notifier,
                    )
                    .loadAccess(),
              ),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            const _ProfitAnalysisCard(),
            const SizedBox(height: AppConstants.spacingLg),
            _FeatureGrid(
              storeId: accessContext.store.id,
              canUpdateStore: state.can(AppPermissionCodes.storeUpdate),
              canViewProduct: state.can(AppPermissionCodes.productView),
              canViewArea: state.can(AppPermissionCodes.areaView),
              canManageStaff:
                  state.can(AppPermissionCodes.staffView) ||
                  state.can(AppPermissionCodes.staffInvite) ||
                  state.can(AppPermissionCodes.staffUpdate) ||
                  state.can(AppPermissionCodes.staffRemove),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RefreshErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(
                'Đang dùng dữ liệu đã lưu. $message',
                style: AppTextStyles.bodyXs,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _ProfitAnalysisCard extends StatelessWidget {
  const _ProfitAnalysisCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng quan hôm nay',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingXl),
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Bạn chưa tạo hóa đơn để phân tích lãi lỗ',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final int storeId;
  final bool canUpdateStore;
  final bool canViewProduct;
  final bool canViewArea;
  final bool canManageStaff;

  const _FeatureGrid({
    required this.storeId,
    required this.canUpdateStore,
    required this.canViewProduct,
    required this.canViewArea,
    required this.canManageStaff,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _FeatureItemData(
        'Sản phẩm',
        Icons.inventory_2_outlined,
        isEnabled: canViewProduct,
        disabledMessage: 'Bạn chưa có quyền xem sản phẩm',
        onTap: () => context.goNamed(
          RouteNames.storeProductManagement,
          pathParameters: {'storeId': storeId.toString()},
        ),
      ),
      const _FeatureItemData('Bán hàng', Icons.shopping_cart_outlined),
      _FeatureItemData(
        'Order giọng nói',
        Icons.graphic_eq_rounded,
        isEnabled: true,
        onTap: () => context.goNamed(
          RouteNames.storeVoiceOrder,
          pathParameters: {'storeId': storeId.toString()},
        ),
      ),
      const _FeatureItemData('Báo cáo', Icons.bar_chart_rounded),
      const _FeatureItemData('Thu chi', Icons.payments_outlined),
      const _FeatureItemData('Khuyến mãi', Icons.local_offer_outlined),
      _FeatureItemData(
        'Quản lý kho',
        Icons.apps_rounded,
        isEnabled: true,
        onTap: () => context.goNamed(
          RouteNames.storeInventoryManagement,
          pathParameters: {'storeId': storeId.toString()},
        ),
      ),
      _FeatureItemData(
        'Quản lý bàn',
        Icons.table_restaurant_outlined,
        isEnabled: canViewArea,
        disabledMessage: 'Bạn chưa có quyền xem quản lý bàn',
        onTap: () => context.goNamed(
          RouteNames.storeTableManagement,
          pathParameters: {'storeId': storeId.toString()},
        ),
      ),
      _FeatureItemData(
        'Cài đặt',
        Icons.settings_outlined,
        isEnabled: canUpdateStore,
        disabledMessage: 'Bạn chưa có quyền cập nhật cửa hàng',
      ),
      _FeatureItemData(
        'Nhân viên',
        Icons.groups_outlined,
        isEnabled: canManageStaff,
        disabledMessage: 'Bạn chưa có quyền quản lý nhân viên',
        onTap: () => context.goNamed(
          RouteNames.storeStaffManagement,
          pathParameters: {'storeId': storeId.toString()},
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppConstants.spacingMd,
        crossAxisSpacing: AppConstants.spacingMd,
        childAspectRatio: 1.08,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _FeatureTile(item: items[index]),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _FeatureItemData item;

  const _FeatureTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final foregroundColor = item.isEnabled
        ? AppColors.textPrimary
        : AppColors.textDisabled;
    final iconColor = item.isEnabled ? AppColors.primary : AppColors.textMuted;

    return Card(
      child: InkWell(
        onTap: item.isEnabled
            ? (item.onTap ?? () => _showComingSoon(context, item.title))
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.isEnabled
                      ? AppColors.primaryLight
                      : AppColors.muted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Icon(item.icon, color: iconColor),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                item.title,
                style: AppTextStyles.labelSm.copyWith(color: foregroundColor),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!item.isEnabled) ...[
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  item.disabledMessage ?? 'Sắp triển khai',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 44),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () => context.goNamed(RouteNames.myStores),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Về danh sách cửa hàng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBackToStores;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onBackToStores,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                onPressed: onBackToStores,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Về danh sách cửa hàng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _FeatureItemData {
  final String title;
  final IconData icon;
  final bool isEnabled;
  final String? disabledMessage;
  final VoidCallback? onTap;

  const _FeatureItemData(
    this.title,
    this.icon, {
    this.isEnabled = false,
    this.disabledMessage,
    this.onTap,
  });
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}
