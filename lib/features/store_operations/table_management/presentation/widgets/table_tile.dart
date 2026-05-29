import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/entities/table_status.dart';

class TableTile extends StatelessWidget {
  final DiningTable table;
  final VoidCallback? onTap;

  const TableTile({super.key, required this.table, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(table.status);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: SizedBox(
          height: 112,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    table.name,
                    style: AppTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: _StatusDot(color: statusColor),
                ),
                Center(
                  child: Icon(
                    Icons.table_restaurant_rounded,
                    color: AppColors.textDisabled,
                    size: 42,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '${table.capacity} chỗ',
                    style: AppTextStyles.caption,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    table.status.label,
                    style: AppTextStyles.caption.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(TableStatus status) {
    return switch (status) {
      TableStatus.available => AppColors.success,
      TableStatus.occupied => AppColors.warning,
      TableStatus.reserved => AppColors.info,
      TableStatus.unknown => AppColors.textMuted,
    };
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
