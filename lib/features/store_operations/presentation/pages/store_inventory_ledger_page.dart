import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_ledger_mock_provider.dart';

class StoreInventoryLedgerPage extends ConsumerWidget {
  final int storeId;

  const StoreInventoryLedgerPage({super.key, required this.storeId});

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
    // TODO: Gate this page with AppPermissionCodes.inventoryView or a more
    // specific ledger permission when backend PBAC is available.
    final ledger = ref.watch(storeInventoryLedgerMockProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _InventoryLedgerHeader(storeId: storeId),
            const _InventoryLedgerFilters(),
            _InventoryLedgerSummary(summary: ledger.summary),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  bottom: AppConstants.spacingXxl + AppConstants.spacingLg,
                ),
                itemBuilder: (context, groupIndex) {
                  final group = ledger.groups[groupIndex];
                  return _InventoryLedgerGroup(group: group);
                },
                itemCount: ledger.groups.length,
              ),
            ),
            const _InventoryLedgerBottomActions(),
          ],
        ),
      ),
    );
  }
}

class _InventoryLedgerHeader extends StatelessWidget {
  final int storeId;

  const _InventoryLedgerHeader({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingSm,
        AppConstants.spacingSm,
        AppConstants.spacingXs,
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
              'Sổ kho',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Tìm kiếm sổ kho'),
          ),
          IconButton(
            tooltip: 'Tùy chọn',
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Tùy chọn sổ kho'),
          ),
        ],
      ),
    );
  }
}

class _InventoryLedgerFilters extends StatelessWidget {
  const _InventoryLedgerFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
      ),
      child: Row(
        children: const [
          Expanded(child: _LedgerFilterButton(label: 'Tháng này')),
          SizedBox(width: AppConstants.spacingSm),
          Expanded(child: _LedgerFilterButton(label: 'Phân loại')),
          SizedBox(width: AppConstants.spacingSm),
          Expanded(child: _LedgerFilterButton(label: 'Loại hàng')),
        ],
      ),
    );
  }
}

class _LedgerFilterButton extends StatelessWidget {
  final String label;

  const _LedgerFilterButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showComingSoon(context, label),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
        textStyle: AppTextStyles.labelSm,
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    );
  }
}

class _InventoryLedgerSummary extends StatelessWidget {
  final StoreInventoryLedgerSummaryMock summary;

  const _InventoryLedgerSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.inventory_2_outlined,
            label: 'Tồn đầu kỳ',
            value: summary.openingValueText,
          ),
          _SummaryRow(
            icon: Icons.move_to_inbox_outlined,
            label: 'Nhập trong kỳ',
            value: summary.inboundValueText,
            valueColor: AppColors.success,
          ),
          _SummaryRow(
            icon: Icons.outbox_outlined,
            label: 'Xuất trong kỳ',
            value: summary.outboundValueText,
            valueColor: AppColors.warning,
          ),
          _SummaryRow(
            icon: Icons.warehouse_outlined,
            label: 'Tồn cuối kỳ',
            value: summary.closingValueText,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDisabled, size: 20),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelSm.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryLedgerGroup extends StatelessWidget {
  final StoreInventoryLedgerGroupMock group;

  const _InventoryLedgerGroup({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.accent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          child: Text(
            group.title,
            style: AppTextStyles.labelXs.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Material(
          color: AppColors.surface,
          child: Column(
            children: [
              for (var index = 0; index < group.entries.length; index++) ...[
                _InventoryLedgerEntryTile(entry: group.entries[index]),
                if (index < group.entries.length - 1)
                  const Divider(
                    height: 1,
                    indent: AppConstants.spacingMd,
                    endIndent: AppConstants.spacingMd,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryLedgerEntryTile extends StatelessWidget {
  final StoreInventoryLedgerEntryMock entry;

  const _InventoryLedgerEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final directionColor = switch (entry.direction) {
      StoreInventoryLedgerDirection.inbound => AppColors.success,
      StoreInventoryLedgerDirection.outbound => AppColors.warning,
      StoreInventoryLedgerDirection.adjustment => AppColors.info,
    };
    final directionIcon = switch (entry.direction) {
      StoreInventoryLedgerDirection.inbound => Icons.arrow_downward_rounded,
      StoreInventoryLedgerDirection.outbound => Icons.arrow_upward_rounded,
      StoreInventoryLedgerDirection.adjustment => Icons.sync_alt_rounded,
    };

    return InkWell(
      onTap: () => _showComingSoon(context, entry.referenceCode),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: AppConstants.spacingXs),
              decoration: BoxDecoration(
                color: directionColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: directionColor.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(directionIcon, color: directionColor, size: 16),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    entry.sku,
                    style: AppTextStyles.bodyXs.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${entry.referenceCode} - ${entry.transactionType}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyXs,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.valueText,
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  entry.quantityText,
                  style: AppTextStyles.labelSm.copyWith(
                    color: directionColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryLedgerBottomActions extends StatelessWidget {
  const _InventoryLedgerBottomActions();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          child: Row(
            children: [
              Expanded(
                child: _BottomActionButton(
                  label: 'Xuất hàng',
                  color: AppColors.warning,
                  icon: Icons.outbox_outlined,
                  onPressed: () => _showComingSoon(context, 'Xuất hàng'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: _BottomActionButton(
                  label: 'Kiểm kho',
                  color: AppColors.info,
                  icon: Icons.fact_check_outlined,
                  onPressed: () => _showComingSoon(context, 'Kiểm kho'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: _BottomActionButton(
                  label: 'Nhập hàng',
                  color: AppColors.success,
                  icon: Icons.move_to_inbox_outlined,
                  onPressed: () => _showComingSoon(context, 'Nhập hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _BottomActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.surface,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
        textStyle: AppTextStyles.buttonSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
