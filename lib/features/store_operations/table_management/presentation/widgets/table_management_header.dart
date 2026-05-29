import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import 'table_header_action_menu.dart';

class TableManagementHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onOrdersTap;
  final bool canUseMoreActions;
  final VoidCallback onEditTap;
  final VoidCallback onDownloadQrTap;

  const TableManagementHeader({
    super.key,
    required this.onBack,
    required this.onOrdersTap,
    required this.canUseMoreActions,
    required this.onEditTap,
    required this.onDownloadQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Quay lại',
          ),
          Expanded(
            child: Text(
              'Quản lý bàn',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _HeaderAction(
            icon: Icons.receipt_long_outlined,
            label: 'Đơn hàng',
            onTap: onOrdersTap,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          TableHeaderActionMenu(
            isEnabled: canUseMoreActions,
            onEditTap: onEditTap,
            onDownloadQrTap: onDownloadQrTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXs,
          vertical: AppConstants.spacingXs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
