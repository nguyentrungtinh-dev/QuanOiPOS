import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_export_products_mock_provider.dart';

class StoreInventoryExportDraftSeedData {
  final Map<String, int> quantitiesBySku;

  const StoreInventoryExportDraftSeedData({required this.quantitiesBySku});
}

class StoreInventoryExportDraftPage extends ConsumerWidget {
  final int storeId;
  final StoreInventoryExportDraftSeedData? seedData;

  const StoreInventoryExportDraftPage({
    super.key,
    required this.storeId,
    this.seedData,
  });

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
          StoreAccessStatus.ready => _ReadyView(
            storeId: storeId,
            seedData: seedData,
          ),
        },
      ),
    );
  }
}

class _ReadyView extends ConsumerStatefulWidget {
  final int storeId;
  final StoreInventoryExportDraftSeedData? seedData;

  const _ReadyView({required this.storeId, this.seedData});

  @override
  ConsumerState<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends ConsumerState<_ReadyView> {
  late final Map<String, int> _quantitiesBySku;

  @override
  void initState() {
    super.initState();
    _quantitiesBySku = {...?widget.seedData?.quantitiesBySku};
  }

  int get _totalQuantity {
    return _quantitiesBySku.values.fold(0, (total, quantity) {
      return total + quantity;
    });
  }

  void _addProduct() {
    context.goNamed(
      RouteNames.storeInventoryExportProducts,
      pathParameters: {'storeId': widget.storeId.toString()},
      extra: StoreInventoryExportDraftSeedData(
        quantitiesBySku: Map.unmodifiable(_quantitiesBySku),
      ),
    );
  }

  void _backToProducts() {
    context.goNamed(
      RouteNames.storeInventoryExportProducts,
      pathParameters: {'storeId': widget.storeId.toString()},
      extra: StoreInventoryExportDraftSeedData(
        quantitiesBySku: Map.unmodifiable(_quantitiesBySku),
      ),
    );
  }

  void _incrementProduct(StoreInventoryExportProductMockItem product) {
    setState(() {
      _quantitiesBySku[product.sku] = (_quantitiesBySku[product.sku] ?? 0) + 1;
    });
  }

  void _decrementProduct(StoreInventoryExportProductMockItem product) {
    setState(() {
      final currentQuantity = _quantitiesBySku[product.sku] ?? 0;
      if (currentQuantity <= 1) {
        _quantitiesBySku.remove(product.sku);
        return;
      }

      _quantitiesBySku[product.sku] = currentQuantity - 1;
    });
  }

  void _removeProduct(StoreInventoryExportProductMockItem product) {
    setState(() {
      _quantitiesBySku.remove(product.sku);
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Replace mock product selection with API-backed export draft data.
    final products = ref.watch(storeInventoryExportProductsMockProvider);
    final selectedProducts = products
        .where((product) => (_quantitiesBySku[product.sku] ?? 0) > 0)
        .toList(growable: false);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _InventoryExportDraftHeader(onBack: _backToProducts),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingLg),
                children: [
                  _AddProductOutlineButton(onPressed: _addProduct),
                  if (selectedProducts.isEmpty)
                    const _EmptyDraftProductView()
                  else
                    Material(
                      color: AppColors.surface,
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < selectedProducts.length;
                            index++
                          ) ...[
                            _DraftProductTile(
                              product: selectedProducts[index],
                              quantity:
                                  _quantitiesBySku[selectedProducts[index]
                                      .sku] ??
                                  0,
                              onIncrement: () =>
                                  _incrementProduct(selectedProducts[index]),
                              onDecrement: () =>
                                  _decrementProduct(selectedProducts[index]),
                              onRemove: () =>
                                  _removeProduct(selectedProducts[index]),
                            ),
                            if (index < selectedProducts.length - 1)
                              const Divider(
                                height: 1,
                                indent: AppConstants.spacingMd,
                                endIndent: AppConstants.spacingMd,
                              ),
                          ],
                        ],
                      ),
                    ),
                  _DraftSummary(
                    productCount: selectedProducts.length,
                    totalQuantity: _totalQuantity,
                  ),
                  const _DraftNoteRow(),
                ],
              ),
            ),
            const _DraftBottomActions(),
          ],
        ),
      ),
    );
  }
}

class _InventoryExportDraftHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _InventoryExportDraftHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingXs,
        AppConstants.spacingSm,
        AppConstants.spacingXs,
        AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('inventory_export_draft_back_action'),
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Tạo phiếu xuất hàng',
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _AddProductOutlineButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddProductOutlineButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: OutlinedButton.icon(
        key: const Key('inventory_export_draft_add_product_action'),
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Thêm sản phẩm'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          textStyle: AppTextStyles.labelSm,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }
}

class _DraftProductTile extends StatelessWidget {
  final StoreInventoryExportProductMockItem product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _DraftProductTile({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const _ProductThumb(),
              Positioned(
                left: -8,
                top: -8,
                child: InkWell(
                  key: Key('inventory_export_draft_remove_${product.sku}'),
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.surface,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(product.sku, style: AppTextStyles.bodyXs),
                const SizedBox(height: AppConstants.spacingSm),
                _ProductQuantityStepper(
                  sku: product.sku,
                  quantity: quantity,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Giá: 0',
                style: AppTextStyles.bodyXs.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                '0',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductQuantityStepper extends StatelessWidget {
  final String sku;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ProductQuantityStepper({
    required this.sku,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('inventory_export_draft_product_stepper_$sku'),
      height: 36,
      constraints: const BoxConstraints(minWidth: 112),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityIconButton(
            key: Key('inventory_export_draft_product_decrement_$sku'),
            icon: Icons.remove_rounded,
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 36,
            child: Text(
              quantity.toString(),
              key: Key('inventory_export_draft_product_quantity_$sku'),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityIconButton(
            key: Key('inventory_export_draft_product_increment_$sku'),
            icon: Icons.add_rounded,
            onPressed: onIncrement,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _QuantityIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _QuantityIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textMuted,
        size: 22,
      ),
    );
  }
}

class _DraftSummary extends StatelessWidget {
  final int productCount;
  final int totalQuantity;

  const _DraftSummary({
    required this.productCount,
    required this.totalQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingSm),
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Column(
        children: [
          _DraftSummaryRow(
            label: 'Tổng số lượng',
            value: '$totalQuantity',
            valueKey: const Key('inventory_export_draft_total_quantity'),
          ),
          _DraftSummaryRow(
            label: 'Sản phẩm',
            value: '$productCount',
            isIndented: true,
            valueKey: const Key('inventory_export_draft_product_count'),
          ),
          const _DraftSummaryRow(
            label: 'Tổng cộng',
            value: '0',
            isTotal: true,
            valueColor: AppColors.primary,
            valueKey: Key('inventory_export_draft_total_amount'),
          ),
        ],
      ),
    );
  }
}

class _DraftSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isIndented;
  final Color? valueColor;
  final Key? valueKey;

  const _DraftSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isIndented = false,
    this.valueColor,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = isTotal
        ? AppTextStyles.label.copyWith(fontWeight: FontWeight.w800)
        : AppTextStyles.bodySm.copyWith(
            color: isIndented ? AppColors.textMuted : AppColors.textSecondary,
            fontWeight: isIndented ? FontWeight.w500 : FontWeight.w600,
          );
    final valueStyle = (isTotal ? AppTextStyles.h4 : AppTextStyles.labelSm)
        .copyWith(
          color: valueColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isIndented
            ? AppConstants.spacingLg + AppConstants.spacingMd
            : AppConstants.spacingMd,
        AppConstants.spacingXs,
        AppConstants.spacingMd,
        AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          Text(label, style: labelStyle),
          const Spacer(),
          Text(value, key: valueKey, style: valueStyle),
        ],
      ),
    );
  }
}

class _DraftNoteRow extends StatelessWidget {
  const _DraftNoteRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingSm),
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showComingSoon(context, 'Ghi chú đơn hàng'),
              child: Text(
                'Ghi chú đơn hàng',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => _showComingSoon(context, 'Ảnh phiếu xuất'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.square(48),
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Icon(Icons.image_outlined, size: 22),
          ),
        ],
      ),
    );
  }
}

class _DraftBottomActions extends StatelessWidget {
  const _DraftBottomActions();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: ElevatedButton(
            key: const Key('inventory_export_draft_complete_action'),
            onPressed: () => _showComingSoon(context, 'Hoàn thành phiếu xuất'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              textStyle: AppTextStyles.buttonSm,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Text('Hoàn thành'),
          ),
        ),
      ),
    );
  }
}

class _EmptyDraftProductView extends StatelessWidget {
  const _EmptyDraftProductView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Text(
        'Chưa có sản phẩm xuất hàng',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
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
