import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_stock_mock_provider.dart';

class StoreInventoryStockPage extends ConsumerWidget {
  final int storeId;

  const StoreInventoryStockPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: accessState.status == StoreAccessStatus.ready
          ? FloatingActionButton(
              onPressed: () => _showComingSoon(context, 'Thêm tồn kho'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: switch (accessState.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message:
                accessState.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
            actionLabel: 'Về danh sách cửa hàng',
            onAction: () => context.goNamed(RouteNames.myStores),
          ),
          StoreAccessStatus.error => _BlockedView(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải thông tin cửa hàng',
            message: accessState.errorMessage ?? 'Vui lòng thử lại sau.',
            actionLabel: 'Thử lại',
            onAction: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready => _ReadyView(storeId: storeId),
        },
      ),
    );
  }
}

class _ReadyView extends ConsumerWidget {
  final int storeId;

  const _ReadyView({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Gate this page with AppPermissionCodes.inventoryView when PBAC is
    // enabled for inventory stock.
    final items = ref.watch(storeInventoryStockMockProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _InventoryStockHeader(storeId: storeId),
            const _InventoryStockFilters(),
            const _InventoryStockSummary(
              totalQuantity: 158,
              totalValue: '84.000',
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingXxl),
                itemBuilder: (context, index) {
                  return _InventoryStockTile(item: items[index]);
                },
                separatorBuilder: (context, index) => const Divider(
                  indent: AppConstants.spacingMd,
                  endIndent: AppConstants.spacingMd,
                ),
                itemCount: items.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryStockHeader extends StatelessWidget {
  final int storeId;

  const _InventoryStockHeader({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingSm,
        AppConstants.spacingSm,
        AppConstants.spacingSm,
        AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.goNamed(
              RouteNames.storeInventoryManagement,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          const Expanded(child: _InventorySearchField()),
          const SizedBox(width: AppConstants.spacingXs),
          IconButton(
            tooltip: 'Kho',
            icon: const Icon(Icons.warehouse_outlined),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Kho'),
          ),
        ],
      ),
    );
  }
}

class _InventorySearchField extends StatelessWidget {
  const _InventorySearchField();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          hintText: 'Tìm tên, mã SKU, ...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            tooltip: 'Quét mã',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _showComingSoon(context, 'Quét mã'),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingSm,
          ),
        ),
      ),
    );
  }
}

class _InventoryStockFilters extends StatelessWidget {
  const _InventoryStockFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingMd,
      ),
      child: Row(
        children: const [
          Expanded(child: _FilterChipButton(label: 'Danh mục')),
          SizedBox(width: AppConstants.spacingSm),
          Expanded(child: _FilterChipButton(label: 'Trạng thái')),
          SizedBox(width: AppConstants.spacingSm),
          Expanded(child: _FilterChipButton(label: 'Sắp xếp')),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;

  const _FilterChipButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showComingSoon(context, label),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
        textStyle: AppTextStyles.labelSm,
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    );
  }
}

class _InventoryStockSummary extends StatelessWidget {
  final int totalQuantity;
  final String totalValue;

  const _InventoryStockSummary({
    required this.totalQuantity,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryText(label: 'Số lượng', value: '$totalQuantity'),
          ),
          Expanded(
            child: _SummaryText(label: 'Giá trị tồn', value: totalValue),
          ),
        ],
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryStockTile extends StatelessWidget {
  final StoreInventoryStockMockItem item;

  const _InventoryStockTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => _showComingSoon(context, item.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          child: Row(
            children: [
              const _ProductThumbnail(),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.sku,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Kho: ${item.stockText}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.secondaryQuantity,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textDisabled,
        size: 28,
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
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
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
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

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}
