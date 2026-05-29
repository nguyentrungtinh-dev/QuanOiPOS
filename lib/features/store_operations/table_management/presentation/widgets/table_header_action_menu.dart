import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';

enum TableHeaderActionMenuItem { edit, downloadQr }

class TableHeaderActionMenu extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onEditTap;
  final VoidCallback onDownloadQrTap;

  const TableHeaderActionMenu({
    super.key,
    required this.isEnabled,
    required this.onEditTap,
    required this.onDownloadQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TableHeaderActionMenuItem>(
      key: const Key('table_header_more_button'),
      enabled: isEnabled,
      tooltip: 'Thêm',
      color: AppColors.surface,
      elevation: 8,
      offset: const Offset(0, AppConstants.spacingXxl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (item) {
        switch (item) {
          case TableHeaderActionMenuItem.edit:
            onEditTap();
          case TableHeaderActionMenuItem.downloadQr:
            onDownloadQrTap();
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem<TableHeaderActionMenuItem>(
            key: Key('table_header_edit_action'),
            value: TableHeaderActionMenuItem.edit,
            child: _MenuItemContent(icon: Icons.edit_outlined, label: 'Sửa'),
          ),
          PopupMenuItem<TableHeaderActionMenuItem>(
            key: Key('table_header_download_qr_action'),
            value: TableHeaderActionMenuItem.downloadQr,
            child: _MenuItemContent(
              icon: Icons.download_outlined,
              label: 'Tải QR bàn',
            ),
          ),
        ];
      },
      child: _HeaderMenuAnchor(isEnabled: isEnabled),
    );
  }
}

class _HeaderMenuAnchor extends StatelessWidget {
  final bool isEnabled;

  const _HeaderMenuAnchor({required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? AppColors.textSecondary : AppColors.textDisabled;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXs,
        vertical: AppConstants.spacingXs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.more_vert_rounded, color: color),
          Text('Thêm', style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _MenuItemContent extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItemContent({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyBase.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
