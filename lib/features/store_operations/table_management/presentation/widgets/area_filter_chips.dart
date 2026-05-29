import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/area.dart';

class AreaFilterChips extends StatelessWidget {
  final List<Area> areas;
  final int? selectedAreaId;
  final ValueChanged<int?> onSelected;
  final VoidCallback onManageAreasTap;

  const AreaFilterChips({
    super.key,
    required this.areas,
    required this.selectedAreaId,
    required this.onSelected,
    required this.onManageAreasTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: OutlinedButton(
            key: const Key('manage_areas_button'),
            onPressed: onManageAreasTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(42, 42),
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Icon(Icons.grid_view_rounded, size: 19),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('area_chips_scroll_view'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AreaChip(
                  label: 'Tất cả',
                  isSelected: selectedAreaId == null,
                  onTap: () => onSelected(null),
                ),
                for (final area in areas) ...[
                  const SizedBox(width: AppConstants.spacingSm),
                  _AreaChip(
                    label: area.name,
                    isSelected: selectedAreaId == area.id,
                    onTap: () => onSelected(area.id),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AreaChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AreaChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        foregroundColor: isSelected ? AppColors.primary : AppColors.textMuted,
        backgroundColor: isSelected
            ? AppColors.primaryLight
            : AppColors.surface,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderStrong,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        textStyle: AppTextStyles.labelSm,
      ),
      child: Text(label),
    );
  }
}
