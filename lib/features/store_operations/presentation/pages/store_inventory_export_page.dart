import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_export_mock_provider.dart';

class StoreInventoryExportPage extends ConsumerWidget {
  final int storeId;

  const StoreInventoryExportPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: accessState.status == StoreAccessStatus.ready
          ? FloatingActionButton.extended(
              onPressed: () => context.goNamed(
                RouteNames.storeInventoryExportProducts,
                pathParameters: {'storeId': storeId.toString()},
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo xuất hàng'),
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
    // TODO: Gate this page with AppPermissionCodes.inventoryView or a more
    // specific export permission when backend PBAC is available.
    final exports = ref.watch(storeInventoryExportMockProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _InventoryExportHeader(storeId: storeId),
            const _InventoryExportTabs(),
            const _InventoryExportFilters(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  0,
                  AppConstants.spacingMd,
                  AppConstants.spacingXxl + AppConstants.spacingLg,
                ),
                itemBuilder: (context, index) {
                  return _InventoryExportCard(item: exports[index]);
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppConstants.spacingSm),
                itemCount: exports.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryExportHeader extends StatelessWidget {
  final int storeId;

  const _InventoryExportHeader({required this.storeId});

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
          Expanded(
            child: Text(
              'Sổ xuất hàng',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Tìm kiếm xuất hàng'),
          ),
          IconButton(
            tooltip: 'Tải xuống',
            icon: const Icon(Icons.file_download_outlined),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Tải sổ xuất hàng'),
          ),
        ],
      ),
    );
  }
}

class _InventoryExportTabs extends StatelessWidget {
  const _InventoryExportTabs();

  static const _tabs = ['Tất cả', 'Đang xử lý', 'Hoàn thành', 'Hủy'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          for (final tab in _tabs)
            Expanded(
              child: _InventoryExportTab(
                label: tab,
                isSelected: tab == 'Tất cả',
                onTap: tab == 'Tất cả'
                    ? null
                    : () => _showComingSoon(context, tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _InventoryExportTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _InventoryExportTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.5 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSm.copyWith(
            color: color,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _InventoryExportFilters extends StatelessWidget {
  const _InventoryExportFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingMd,
      ),
      child: Row(
        children: const [
          SizedBox(width: 124, child: _FilterButton(label: 'Tháng này')),
          SizedBox(width: AppConstants.spacingSm),
          SizedBox(width: 124, child: _FilterButton(label: 'Phân loại')),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;

  const _FilterButton({required this.label});

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

class _InventoryExportCard extends StatelessWidget {
  final StoreInventoryExportMockItem item;

  const _InventoryExportCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: () => _showComingSoon(context, item.code),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.code,
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        Text(item.createdAtText, style: AppTextStyles.bodyXs),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.status,
                        style: AppTextStyles.labelXs.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        'Tạo bởi ${item.creatorName}',
                        style: AppTextStyles.bodyXs,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),
              const Divider(height: 1),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tổng cộng',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    item.totalText,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
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
