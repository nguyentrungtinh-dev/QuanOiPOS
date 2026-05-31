import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';

class StoreInventoryManagementPage extends ConsumerWidget {
  final int storeId;

  const StoreInventoryManagementPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý kho'),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(
            RouteNames.storeOverview,
            pathParameters: {'storeId': storeId.toString()},
          ),
        ),
      ),
      body: SafeArea(
        child: switch (state.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message:
                state.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
            actionLabel: 'Về danh sách cửa hàng',
            onAction: () => context.goNamed(RouteNames.myStores),
          ),
          StoreAccessStatus.error => _BlockedView(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải thông tin cửa hàng',
            message: state.errorMessage ?? 'Vui lòng thử lại sau.',
            actionLabel: 'Thử lại',
            onAction: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready => _ReadyView(state: state),
        },
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  final StoreAccessState state;

  const _ReadyView({required this.state});

  @override
  Widget build(BuildContext context) {
    final accessContext = state.context;
    if (accessContext == null) {
      return _BlockedView(
        icon: Icons.storefront_outlined,
        title: 'Chưa có dữ liệu cửa hàng',
        message: 'Vui lòng quay lại danh sách cửa hàng và thử lại.',
        actionLabel: 'Về danh sách cửa hàng',
        onAction: () => context.goNamed(RouteNames.myStores),
      );
    }

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        children: [
          Text(
            accessContext.store.storeName,
            style: AppTextStyles.bodySm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _InventoryActionList(storeId: accessContext.store.id),
        ],
      ),
    );
  }
}

class _InventoryActionList extends StatelessWidget {
  final int storeId;

  const _InventoryActionList({required this.storeId});

  static const _items = [
    _InventoryActionItemData(
      'Nhập kho',
      Icons.move_to_inbox_outlined,
      routeName: RouteNames.storeInventoryImport,
    ),
    _InventoryActionItemData('Xuất kho', Icons.outbox_outlined),
    _InventoryActionItemData(
      'Sổ kho',
      Icons.receipt_long_outlined,
      routeName: RouteNames.storeInventoryLedger,
    ),
    _InventoryActionItemData(
      'Kiểm kho',
      Icons.fact_check_outlined,
      routeName: RouteNames.storeInventoryCheck,
    ),
    _InventoryActionItemData(
      'Tồn kho',
      Icons.warehouse_outlined,
      routeName: RouteNames.storeInventoryStock,
    ),
    _InventoryActionItemData('In mã vạch', Icons.qr_code_2_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Column(
        children: [
          for (var index = 0; index < _items.length; index++) ...[
            _InventoryActionTile(item: _items[index], storeId: storeId),
            if (index < _items.length - 1)
              const Divider(
                height: 1,
                indent: AppConstants.spacingMd,
                endIndent: AppConstants.spacingMd,
              ),
          ],
        ],
      ),
    );
  }
}

class _InventoryActionTile extends StatelessWidget {
  final _InventoryActionItemData item;
  final int storeId;

  const _InventoryActionTile({required this.item, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final routeName = item.routeName;
        if (routeName != null) {
          context.goNamed(
            routeName,
            pathParameters: {'storeId': storeId.toString()},
          );
          return;
        }

        _showComingSoon(context, item.title);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Icon(item.icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Text(
                item.title,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
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

class _InventoryActionItemData {
  final String title;
  final IconData icon;
  final String? routeName;

  const _InventoryActionItemData(this.title, this.icon, {this.routeName});
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}
