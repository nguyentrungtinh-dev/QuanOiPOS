import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/area.dart';
import '../controllers/table_management_state.dart';
import '../providers/table_management_providers.dart';
import 'area_form_bottom_sheet.dart';

class AreaManagementBottomSheet extends ConsumerStatefulWidget {
  final TableManagementAccess access;

  const AreaManagementBottomSheet({super.key, required this.access});

  @override
  ConsumerState<AreaManagementBottomSheet> createState() =>
      _AreaManagementBottomSheetState();
}

class _AreaManagementBottomSheetState
    extends ConsumerState<AreaManagementBottomSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isEditing = false;
  bool _isReordering = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableManagementNotifierProvider(widget.access));
    final areas = _filterAreas(state.areas);
    final canEditList =
        widget.access.canUpdateArea || widget.access.canDeleteArea;

    return SafeArea(
      key: const Key('area_management_sheet'),
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMd,
                AppConstants.spacingSm,
                AppConstants.spacingMd,
                AppConstants.spacingSm,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('edit_areas_button'),
                      onPressed: canEditList
                          ? () => setState(() => _isEditing = !_isEditing)
                          : null,
                      icon: Icon(
                        _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                        size: 20,
                      ),
                      label: Text(_isEditing ? 'Xong' : 'Chỉnh sửa'),
                    ),
                  ),
                  Text(
                    'Khu vực',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      key: const Key('close_area_management_button'),
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingMd,
                AppConstants.spacingLg,
                AppConstants.spacingMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('area_management_search_field'),
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Tìm tên khu vực',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: IconButton.filled(
                      key: const Key('add_area_button'),
                      tooltip: 'Thêm khu vực',
                      onPressed: widget.access.canCreateArea
                          ? () => _showAreaForm(context)
                          : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Expanded(
              child: _AreaList(
                areas: areas,
                canReorder:
                    _isEditing && widget.access.canUpdateArea && _query.isEmpty,
                isEditing: _isEditing,
                isReordering: _isReordering,
                canUpdateArea: widget.access.canUpdateArea,
                canDeleteArea: widget.access.canDeleteArea,
                onSelected: (area) {
                  ref
                      .read(
                        tableManagementNotifierProvider(widget.access).notifier,
                      )
                      .selectArea(area.id);
                  Navigator.of(context).pop();
                },
                onEdit: (area) => _showAreaForm(context, area: area),
                onDelete: _confirmDelete,
                onReorder: _reorderAreas,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Area> _filterAreas(List<Area> areas) {
    if (_query.isEmpty) {
      return areas;
    }

    final query = _query.toLowerCase();
    return areas
        .where((area) => area.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _showAreaForm(BuildContext context, {Area? area}) async {
    final notifier = ref.read(
      tableManagementNotifierProvider(widget.access).notifier,
    );

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AreaFormBottomSheet(
          area: area,
          onSubmit: (name, description) {
            if (area == null) {
              return notifier.createArea(name: name, description: description);
            }

            return notifier.updateArea(
              areaId: area.id,
              name: name,
              description: description,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Area area) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa khu vực?'),
          content: Text('Khu vực "${area.name}" sẽ bị xóa khỏi cửa hàng.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              key: const Key('confirm_delete_area_button'),
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(tableManagementNotifierProvider(widget.access).notifier)
          .deleteArea(area.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa khu vực')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
      }
    }
  }

  Future<void> _reorderAreas(int oldIndex, int newIndex) async {
    final currentAreas = List<Area>.of(
      ref.read(tableManagementNotifierProvider(widget.access)).areas,
    );

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final area = currentAreas.removeAt(oldIndex);
    currentAreas.insert(newIndex, area);

    setState(() => _isReordering = true);
    try {
      await ref
          .read(tableManagementNotifierProvider(widget.access).notifier)
          .reorderAreas(currentAreas);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isReordering = false);
      }
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _AreaList extends StatelessWidget {
  final List<Area> areas;
  final bool canReorder;
  final bool isEditing;
  final bool isReordering;
  final bool canUpdateArea;
  final bool canDeleteArea;
  final ValueChanged<Area> onSelected;
  final ValueChanged<Area> onEdit;
  final ValueChanged<Area> onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _AreaList({
    required this.areas,
    required this.canReorder,
    required this.isEditing,
    required this.isReordering,
    required this.canUpdateArea,
    required this.canDeleteArea,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) {
      return const _EmptyAreaList();
    }

    if (canReorder) {
      return Stack(
        children: [
          ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingLg,
              0,
              AppConstants.spacingLg,
              AppConstants.spacingXl,
            ),
            itemCount: areas.length,
            onReorder: onReorder,
            proxyDecorator: (child, index, animation) {
              return Material(color: Colors.transparent, child: child);
            },
            itemBuilder: (context, index) {
              final area = areas[index];
              return _AreaListTile(
                key: ValueKey('area_${area.id}'),
                area: area,
                index: index,
                isEditing: isEditing,
                showReorderHandle: true,
                canUpdateArea: canUpdateArea,
                canDeleteArea: canDeleteArea,
                onSelected: onSelected,
                onEdit: onEdit,
                onDelete: onDelete,
              );
            },
          ),
          if (isReordering)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingLg,
        0,
        AppConstants.spacingLg,
        AppConstants.spacingXl,
      ),
      itemBuilder: (context, index) {
        final area = areas[index];
        return _AreaListTile(
          key: ValueKey('area_${area.id}'),
          area: area,
          index: index,
          isEditing: isEditing,
          showReorderHandle: false,
          canUpdateArea: canUpdateArea,
          canDeleteArea: canDeleteArea,
          onSelected: onSelected,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacingSm),
      itemCount: areas.length,
    );
  }
}

class _AreaListTile extends StatelessWidget {
  final Area area;
  final int index;
  final bool isEditing;
  final bool showReorderHandle;
  final bool canUpdateArea;
  final bool canDeleteArea;
  final ValueChanged<Area> onSelected;
  final ValueChanged<Area> onEdit;
  final ValueChanged<Area> onDelete;

  const _AreaListTile({
    super.key,
    required this.area,
    required this.index,
    required this.isEditing,
    required this.showReorderHandle,
    required this.canUpdateArea,
    required this.canDeleteArea,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isEditing ? null : () => onSelected(area),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingSm,
          ),
          child: Row(
            children: [
              if (isEditing)
                IconButton(
                  key: Key('delete_area_${area.id}'),
                  tooltip: canDeleteArea ? 'Xóa khu vực' : 'Không có quyền xóa',
                  onPressed: canDeleteArea ? () => onDelete(area) : null,
                  color: AppColors.error,
                  icon: const Icon(Icons.remove_circle_rounded),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.name,
                        style: AppTextStyles.labelSm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (area.description.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.spacingXs),
                        Text(
                          area.description,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isEditing) ...[
                IconButton(
                  key: Key('edit_area_${area.id}'),
                  tooltip: canUpdateArea
                      ? 'Chỉnh sửa khu vực'
                      : 'Không có quyền chỉnh sửa',
                  onPressed: canUpdateArea ? () => onEdit(area) : null,
                  color: AppColors.primary,
                  icon: const Icon(Icons.edit_outlined),
                ),
                if (showReorderHandle)
                  ReorderableDragStartListener(
                    key: Key('reorder_area_${area.id}'),
                    index: index,
                    enabled: canUpdateArea,
                    child: Icon(
                      Icons.open_with_rounded,
                      color: canUpdateArea
                          ? AppColors.textMuted
                          : AppColors.textDisabled,
                    ),
                  )
                else
                  Icon(
                    Icons.open_with_rounded,
                    key: Key('reorder_area_${area.id}'),
                    color: AppColors.textDisabled,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAreaList extends StatelessWidget {
  const _EmptyAreaList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.layers_clear_outlined,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Chưa có khu vực',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            const Text(
              'Thêm khu vực để tổ chức bàn trong cửa hàng.',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
