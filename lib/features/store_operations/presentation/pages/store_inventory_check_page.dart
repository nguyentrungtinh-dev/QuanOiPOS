import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_check_mock_provider.dart';

class StoreInventoryCheckPage extends ConsumerWidget {
  final int storeId;

  const StoreInventoryCheckPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
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
    // enabled for inventory checks.
    final items = ref.watch(storeInventoryCheckMockProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _InventoryCheckHeader(storeId: storeId),
            const _InventoryCheckTabs(),
            const _InventoryCheckFilters(),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyInventoryCheckView()
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      itemBuilder: (context, index) {
                        return _InventoryCheckTile(item: items[index]);
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppConstants.spacingSm),
                      itemCount: items.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCheckHeader extends StatelessWidget {
  final int storeId;

  const _InventoryCheckHeader({required this.storeId});

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
              'Kiểm kho',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Tìm kiếm kiểm kho'),
          ),
          IconButton(
            tooltip: 'Tải xuống',
            icon: const Icon(Icons.file_download_outlined),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Tải phiếu kiểm kho'),
          ),
        ],
      ),
    );
  }
}

class _InventoryCheckTabs extends StatelessWidget {
  const _InventoryCheckTabs();

  static const _tabs = ['Tất cả', 'Đang kiểm kho', 'Đã cân bằng'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          for (final tab in _tabs)
            Expanded(
              child: _InventoryCheckTab(
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

class _InventoryCheckTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _InventoryCheckTab({
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

class _InventoryCheckFilters extends StatelessWidget {
  const _InventoryCheckFilters();

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
          Expanded(child: _FilterButton(label: 'Tháng này')),
          SizedBox(width: AppConstants.spacingSm),
          Expanded(child: _FilterButton(label: 'Phân loại')),
          SizedBox(width: AppConstants.spacingSm),
          Expanded(child: _FilterButton(label: 'Nhân viên')),
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

class _EmptyInventoryCheckView extends StatelessWidget {
  const _EmptyInventoryCheckView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _InventoryCheckEmptyIllustration(),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              'Bạn chưa có phiếu kiểm kho nào!',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: ElevatedButton.icon(
                onPressed: () => _showComingSoon(context, 'Tạo kiểm kho'),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Tạo kiểm kho'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCheckEmptyIllustration extends StatelessWidget {
  const _InventoryCheckEmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 170,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: AppConstants.spacingLg,
            child: Container(
              width: 116,
              height: 138,
              padding: const EdgeInsets.fromLTRB(20, 34, 18, 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppColors.borderStrong),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _IllustrationChecklistRow(isChecked: true),
                  SizedBox(height: AppConstants.spacingXs),
                  _IllustrationChecklistRow(isChecked: true),
                  SizedBox(height: AppConstants.spacingXs),
                  _IllustrationChecklistRow(isChecked: true),
                  SizedBox(height: AppConstants.spacingXs),
                  _IllustrationChecklistRow(isChecked: false),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppConstants.spacingXs,
            child: Container(
              width: 76,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationChecklistRow extends StatelessWidget {
  final bool isChecked;

  const _IllustrationChecklistRow({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isChecked ? AppColors.success : AppColors.muted,
            shape: BoxShape.circle,
          ),
          child: isChecked
              ? const Icon(
                  Icons.check_rounded,
                  color: AppColors.surface,
                  size: 14,
                )
              : null,
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        ),
      ],
    );
  }
}

class _InventoryCheckTile extends StatelessWidget {
  final StoreInventoryCheckMockItem item;

  const _InventoryCheckTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.fact_check_outlined,
          color: AppColors.primary,
        ),
        title: Text(item.title, style: AppTextStyles.labelSm),
        subtitle: Text(item.code, style: AppTextStyles.bodyXs),
        trailing: Text(item.status, style: AppTextStyles.labelXs),
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
