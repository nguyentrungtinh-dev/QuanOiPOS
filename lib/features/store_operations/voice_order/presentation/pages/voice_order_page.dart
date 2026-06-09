import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/voice_order_item.dart';
import '../../domain/entities/voice_order_recognition.dart';
import '../controllers/voice_order_state.dart';
import '../providers/voice_order_providers.dart';

class VoiceOrderPage extends ConsumerWidget {
  final int storeId;

  const VoiceOrderPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: switch (accessState.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => const _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message: 'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
          ),
          StoreAccessStatus.error => _ErrorView(
            message:
                accessState.errorMessage ??
                'Không thể tải thông tin của cửa hàng',
            onRetry: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready =>
            accessState.can(AppPermissionCodes.dashboardView)
                ? _VoiceOrderBody(storeId: storeId)
                : const _BlockedView(
                    icon: Icons.visibility_off_outlined,
                    title: 'Bạn chưa có quyền dùng order giọng nói',
                    message:
                        'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền xem tổng quan.',
                  ),
        },
      ),
    );
  }
}

class _VoiceOrderBody extends ConsumerWidget {
  final int storeId;

  const _VoiceOrderBody({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceOrderNotifierProvider);
    final notifier = ref.read(voiceOrderNotifierProvider.notifier);
    final recognition = state.recognition;

    return Stack(
      children: [
        const Positioned.fill(child: _PastelBackground()),
        Column(
          children: [
            _Header(storeId: storeId),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  AppConstants.spacingSm,
                  AppConstants.spacingMd,
                  132,
                ),
                children: [
                  _TableSelector(recognition: recognition),
                  const SizedBox(height: AppConstants.spacingMd),
                  if (recognition == null)
                    const _EmptyOrderState()
                  else ...[
                    _OrderItemsList(
                      recognition: recognition,
                      onIncreaseItem: notifier.increaseItemQuantity,
                      onDecreaseItem: notifier.decreaseItemQuantity,
                      onUpdateItem: notifier.updateItem,
                    ),
                    if (recognition.missingFields.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      _InlineMessage(
                        icon: Icons.warning_amber_rounded,
                        message:
                            'Thiếu thông tin: ${recognition.missingFields.join(', ')}',
                      ),
                    ],
                    if (recognition.errors.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      _InlineMessage(
                        icon: Icons.error_outline_rounded,
                        message: recognition.errors.join('\n'),
                      ),
                    ],
                  ],
                  if (state.errorMessage != null &&
                      state.errorMessage!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingMd),
                    _InlineMessage(
                      icon: state.status == VoiceOrderStatus.permissionDenied
                          ? Icons.mic_off_outlined
                          : Icons.error_outline_rounded,
                      message: state.errorMessage!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppConstants.spacingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VoiceStatusPill(state: state),
              const SizedBox(height: AppConstants.spacingSm),
              _HoldMicButton(
                state: state,
                onStart: notifier.startRecording,
                onStop: () => notifier.stopAndRecognize(storeId),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PastelBackground extends StatelessWidget {
  const _PastelBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.13),
            AppColors.surface,
            AppColors.info.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.10),
          ],
          stops: const [0, 0.38, 0.72, 1],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int storeId;

  const _Header({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => context.goNamed(
              RouteNames.storeOverview,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bán hàng',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'Hôm nay, 00:33',
                  style: AppTextStyles.bodyXs,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.goNamed(
              RouteNames.storeOverview,
              pathParameters: {'storeId': storeId.toString()},
            ),
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }
}

class _TableSelector extends StatelessWidget {
  final VoiceOrderRecognition? recognition;

  const _TableSelector({required this.recognition});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _tableLabel(recognition),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _EmptyOrderState extends StatelessWidget {
  const _EmptyOrderState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 280);
  }
}

class _OrderItemsList extends StatelessWidget {
  final VoiceOrderRecognition recognition;
  final ValueChanged<VoiceOrderItem> onIncreaseItem;
  final ValueChanged<VoiceOrderItem> onDecreaseItem;
  final void Function(
    VoiceOrderItem original, {
    required String productName,
    required int quantity,
    String? note,
  })
  onUpdateItem;

  const _OrderItemsList({
    required this.recognition,
    required this.onIncreaseItem,
    required this.onDecreaseItem,
    required this.onUpdateItem,
  });

  @override
  Widget build(BuildContext context) {
    if (recognition.items.isEmpty) {
      return const _GlassPanel(
        child: Text('Chưa có món nào.', style: AppTextStyles.bodySm),
      );
    }

    return Column(
      children: [
        for (final item in recognition.items) ...[
          _OrderItemCard(
            item: item,
            onIncrease: () => onIncreaseItem(item),
            onDecrease: () => onDecreaseItem(item),
            onUpdate: onUpdateItem,
          ),
          if (item != recognition.items.last)
            const SizedBox(height: AppConstants.spacingSm),
        ],
      ],
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final VoiceOrderItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final void Function(
    VoiceOrderItem original, {
    required String productName,
    required int quantity,
    String? note,
  })
  onUpdate;

  const _OrderItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final note = item.note?.trim();

    return _GlassPanel(
      onTap: () => _showEditSheet(context, item, onUpdate),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text('0', style: AppTextStyles.bodySm),
                const SizedBox(height: AppConstants.spacingMd),
                Text(
                  note == null || note.isEmpty
                      ? 'Ghi chú...'
                      : 'Ghi chú: $note',
                  style: AppTextStyles.bodySm.copyWith(
                    color: note == null || note.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          _QuantityControl(
            quantity: item.quantity,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(icon: Icons.remove_rounded, onTap: onDecrease),
        const SizedBox(width: AppConstants.spacingMd),
        Text(
          '$quantity',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        _StepperButton(icon: Icons.add_rounded, onTap: onIncrease),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      ),
    );
  }
}

class _HoldMicButton extends StatelessWidget {
  final VoiceOrderState state;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _HoldMicButton({
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = state.status == VoiceOrderStatus.recording;
    final isProcessing = state.status == VoiceOrderStatus.recognizing;
    final color = isRecording ? AppColors.error : AppColors.primary;

    return Center(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: isProcessing ? null : (_) => onStart(),
        onPointerUp: isProcessing ? null : (_) => onStop(),
        onPointerCancel: isProcessing ? null : (_) => onStop(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.86),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: isProcessing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: color,
                      ),
                    )
                  : Icon(Icons.mic_rounded, color: color, size: 34),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceStatusPill extends StatelessWidget {
  final VoiceOrderState state;

  const _VoiceStatusPill({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == VoiceOrderStatus.idle ||
        state.status == VoiceOrderStatus.success) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        _statusTitle(state),
        style: AppTextStyles.labelSm,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppConstants.spacingMd),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InlineMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(child: Text(message, style: AppTextStyles.bodySm)),
        ],
      ),
    );
  }
}

Future<void> _showEditSheet(
  BuildContext context,
  VoiceOrderItem item,
  void Function(
    VoiceOrderItem original, {
    required String productName,
    required int quantity,
    String? note,
  })
  onUpdate,
) async {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _EditOrderItemSheet(
      item: item,
      onUpdate: onUpdate,
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class _EditOrderItemSheet extends StatefulWidget {
  final VoiceOrderItem item;
  final VoidCallback onClose;
  final void Function(
    VoiceOrderItem original, {
    required String productName,
    required int quantity,
    String? note,
  })
  onUpdate;

  const _EditOrderItemSheet({
    required this.item,
    required this.onClose,
    required this.onUpdate,
  });

  @override
  State<_EditOrderItemSheet> createState() => _EditOrderItemSheetState();
}

class _EditOrderItemSheetState extends State<_EditOrderItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.productName);
    _noteController = TextEditingController(
      text: widget.item.note?.trim() ?? '',
    );
    _quantity = widget.item.quantity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: AppConstants.spacingSm,
        right: AppConstants.spacingSm,
        bottom:
            MediaQuery.viewInsetsOf(context).bottom + AppConstants.spacingSm,
      ),
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chỉnh sửa',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.ramen_dining_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên hàng'),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Center(
                child: _EditableQuantityControl(
                  quantity: _quantity,
                  onDecrease: () {
                    if (_quantity <= 1) {
                      return;
                    }
                    setState(() => _quantity -= 1);
                  },
                  onIncrease: () => setState(() => _quantity += 1),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      child: const Text('Xóa'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onUpdate(
                          widget.item,
                          productName: _nameController.text,
                          quantity: _quantity,
                          note: _noteController.text,
                        );
                        widget.onClose();
                      },
                      child: const Text('Lưu'),
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

class _EditableQuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _EditableQuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(icon: Icons.remove_rounded, onTap: onDecrease),
        const SizedBox(width: AppConstants.spacingLg),
        Text(
          '$quantity',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppConstants.spacingLg),
        _StepperButton(icon: Icons.add_rounded, onTap: onIncrease),
      ],
    );
  }
}

String _statusTitle(VoiceOrderState state) {
  return switch (state.status) {
    VoiceOrderStatus.recording => 'Đang nghe...',
    VoiceOrderStatus.recognizing => 'Đang xử lý...',
    VoiceOrderStatus.error ||
    VoiceOrderStatus.permissionDenied => 'Nhấn giữ mic để thử lại',
    _ => 'Nhấn giữ mic để đọc order',
  };
}

String _tableLabel(VoiceOrderRecognition? recognition) {
  final tableName = recognition?.tableName?.trim();
  if (tableName != null && tableName.isNotEmpty) {
    final normalized = tableName.toLowerCase();
    if (normalized.startsWith('phòng') || normalized.startsWith('phong')) {
      return tableName;
    }
    if (normalized.startsWith('bàn') || normalized.startsWith('ban')) {
      return tableName;
    }
    return 'phòng $tableName';
  }

  final tableId = recognition?.tableId;
  if (tableId != null) {
    return 'phòng $tableId';
  }

  return 'Chọn phòng/bàn';
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
              child: OutlinedButton.icon(
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

  const _ErrorView({required this.message, required this.onRetry});

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
            Text(message, style: AppTextStyles.bodySm),
            const SizedBox(height: AppConstants.spacingLg),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
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
