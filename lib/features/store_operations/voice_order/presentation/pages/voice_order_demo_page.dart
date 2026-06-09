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

class VoiceOrderDemoPage extends ConsumerWidget {
  final int storeId;

  const VoiceOrderDemoPage({super.key, required this.storeId});

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
                accessState.errorMessage ?? 'Không thể tải thông tin cửa hàng',
            onRetry: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready =>
            accessState.can(AppPermissionCodes.dashboardView)
                ? _VoiceOrderBody(storeId: storeId)
                : const _BlockedView(
                    icon: Icons.visibility_off_outlined,
                    title: 'Bạn chưa có quyền dùng demo order giọng nói',
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

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          _Header(storeId: storeId),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMd,
                AppConstants.spacingXl,
                AppConstants.spacingMd,
                AppConstants.spacingXxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HoldMicButton(
                    state: state,
                    onStart: notifier.startRecording,
                    onStop: () => notifier.stopAndRecognize(storeId),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  _VoiceStatusText(state: state),
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
                  if (state.recognition != null) ...[
                    const SizedBox(height: AppConstants.spacingLg),
                    _RecognitionResult(
                      recognition: state.recognition!,
                      onConfirm: () {},
                      onCancel: () => _showCancelDialog(context, ref),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hủy order giọng nói?'),
          content: const Text('Danh sách món vừa nhận diện sẽ bị xóa.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Xem lại'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      await ref.read(voiceOrderNotifierProvider.notifier).clear();
    }
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
        AppConstants.spacingMd,
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
            child: Text(
              'Order giọng nói',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
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
    final outerColor = isRecording
        ? AppColors.error.withValues(alpha: 0.12)
        : AppColors.primaryLight;
    final innerColor = isRecording ? AppColors.error : AppColors.primary;

    return Center(
      child: GestureDetector(
        onTapDown: isProcessing ? null : (_) => onStart(),
        onTapUp: isProcessing ? null : (_) => onStop(),
        onTapCancel: isProcessing ? null : onStop,
        child: Container(
          width: 132,
          height: 132,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: outerColor,
            shape: BoxShape.circle,
            border: Border.all(color: innerColor.withValues(alpha: 0.22)),
          ),
          child: Container(
            width: 90,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isProcessing ? AppColors.textMuted : innerColor,
              shape: BoxShape.circle,
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.surface,
                    ),
                  )
                : const Icon(
                    Icons.mic_rounded,
                    color: AppColors.surface,
                    size: 42,
                  ),
          ),
        ),
      ),
    );
  }
}

class _VoiceStatusText extends StatelessWidget {
  final VoiceOrderState state;

  const _VoiceStatusText({required this.state});

  @override
  Widget build(BuildContext context) {
    final title = switch (state.status) {
      VoiceOrderStatus.recording => 'Đang nghe...',
      VoiceOrderStatus.recognizing => 'Đang xử lý...',
      VoiceOrderStatus.success => 'Kiểm tra lại order',
      VoiceOrderStatus.error ||
      VoiceOrderStatus.permissionDenied => 'Nhấn giữ mic để thử lại',
      _ => 'Nhấn giữ mic để đọc order',
    };
    final subtitle = switch (state.status) {
      VoiceOrderStatus.recording => 'Thả tay để gửi lên AI nhận diện món.',
      VoiceOrderStatus.recognizing => 'Vui lòng đợi phản hồi từ backend.',
      VoiceOrderStatus.success =>
        'Kiểm tra bàn, món, số lượng và note trước khi xác nhận.',
      _ => 'Đọc rõ bàn, tên món, số lượng và ghi chú nếu có.',
    };

    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          subtitle,
          style: AppTextStyles.bodySm,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RecognitionResult extends StatelessWidget {
  final VoiceOrderRecognition recognition;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _RecognitionResult({
    required this.recognition,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          child: Row(
            children: [
              const Icon(
                Icons.table_restaurant_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bàn',
                      style: AppTextStyles.bodyXs.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      _tableLabel(recognition),
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Món đã đọc',
                style: AppTextStyles.labelSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              if (recognition.items.isEmpty)
                Text('Chưa có món nào.', style: AppTextStyles.bodySm)
              else
                for (final item in recognition.items) ...[
                  _RecognizedItemRow(item: item),
                  if (item != recognition.items.last)
                    const Divider(height: AppConstants.spacingLg),
                ],
            ],
          ),
        ),
        if (recognition.missingFields.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingMd),
          _InlineMessage(
            icon: Icons.warning_amber_rounded,
            message: 'Thiếu thông tin: ${recognition.missingFields.join(', ')}',
          ),
        ],
        if (recognition.errors.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingMd),
          _InlineMessage(
            icon: Icons.error_outline_rounded,
            message: recognition.errors.join('\n'),
          ),
        ],
        const SizedBox(height: AppConstants.spacingLg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Xác nhận'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _tableLabel(VoiceOrderRecognition recognition) {
    final tableName = recognition.tableName?.trim();
    if (tableName != null && tableName.isNotEmpty) {
      final normalized = tableName.toLowerCase();
      return normalized.startsWith('bàn') || normalized.startsWith('ban')
          ? tableName
          : 'Bàn $tableName';
    }

    final tableId = recognition.tableId;
    if (tableId != null) {
      return 'Bàn $tableId';
    }

    return 'Chưa rõ bàn';
  }
}

class _RecognizedItemRow extends StatelessWidget {
  final VoiceOrderItem item;

  const _RecognizedItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final note = item.note?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${item.quantity}',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: AppTextStyles.labelSm),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingXs),
                Text('Ghi chú: $note', style: AppTextStyles.bodyXs),
              ],
            ],
          ),
        ),
      ],
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
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: child,
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
        color: AppColors.primaryLight,
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
