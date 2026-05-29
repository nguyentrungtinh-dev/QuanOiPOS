import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/entities/table_area_group.dart';
import '../controllers/table_management_state.dart';
import '../providers/table_management_providers.dart';
import '../widgets/area_filter_chips.dart';
import '../widgets/area_form_bottom_sheet.dart';
import '../widgets/table_form_bottom_sheet.dart';

class TableSettingsPage extends ConsumerWidget {
  final int storeId;

  const TableSettingsPage({super.key, required this.storeId});

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
            title: 'Không có quyền truy cập',
            message:
                accessState.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
            onAction: () => context.goNamed(RouteNames.myStores),
            actionLabel: 'Về danh sách cửa hàng',
          ),
          StoreAccessStatus.error => _ErrorView(
            message: accessState.errorMessage ?? 'Không thể tải quyền cửa hàng',
            onRetry: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready => _TableSettingsReadyView(
            storeId: storeId,
            accessState: accessState,
          ),
        },
      ),
    );
  }
}

class _TableSettingsReadyView extends ConsumerWidget {
  final int storeId;
  final StoreAccessState accessState;

  const _TableSettingsReadyView({
    required this.storeId,
    required this.accessState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!accessState.can(AppPermissionCodes.areaView)) {
      return _BlockedView(
        title: 'Bạn chưa có quyền xem cài đặt bàn',
        message: 'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
        onAction: () => context.goNamed(
          RouteNames.storeTableManagement,
          pathParameters: {'storeId': storeId.toString()},
        ),
        actionLabel: 'Về quản lý bàn',
      );
    }

    final access = TableManagementAccess(
      storeId: storeId,
      canViewAreas: accessState.can(AppPermissionCodes.areaView),
      canViewTables: accessState.can(AppPermissionCodes.tableView),
      canCreateArea: accessState.can(AppPermissionCodes.areaCreate),
      canUpdateArea: accessState.can(AppPermissionCodes.areaUpdate),
      canDeleteArea: accessState.can(AppPermissionCodes.areaDelete),
      canCreateTable: accessState.can(AppPermissionCodes.tableCreate),
      canUpdateTable: accessState.can(AppPermissionCodes.tableUpdate),
    );
    final state = ref.watch(tableManagementNotifierProvider(access));
    final notifier = ref.read(tableManagementNotifierProvider(access).notifier);

    return Column(
      children: [
        _SettingsHeader(
          onBack: () => context.goNamed(
            RouteNames.storeTableManagement,
            pathParameters: {'storeId': storeId.toString()},
          ),
        ),
        Expanded(
          child: switch (state.status) {
            TableManagementStatus.initial ||
            TableManagementStatus.loading => const _LoadingView(),
            TableManagementStatus.forbidden => _BlockedView(
              title: 'Bạn chưa có quyền xem cài đặt bàn',
              message:
                  state.errorMessage ??
                  'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
              onAction: () => context.goNamed(
                RouteNames.storeTableManagement,
                pathParameters: {'storeId': storeId.toString()},
              ),
              actionLabel: 'Về quản lý bàn',
            ),
            TableManagementStatus.error => _ErrorView(
              message: state.errorMessage ?? 'Không thể tải cài đặt bàn',
              onRetry: notifier.load,
            ),
            TableManagementStatus.ready => _SettingsContent(
              state: state,
              access: access,
              onRefresh: notifier.load,
              onAreaSelected: notifier.selectArea,
            ),
          },
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _SettingsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              'Cài đặt bàn',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  final TableManagementState state;
  final TableManagementAccess access;
  final Future<void> Function() onRefresh;
  final ValueChanged<int?> onAreaSelected;

  const _SettingsContent({
    required this.state,
    required this.access,
    required this.onRefresh,
    required this.onAreaSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = _buildSections(state);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingMd,
              AppConstants.spacingMd,
              AppConstants.spacingMd,
              96,
            ),
            children: [
              AreaFilterChips(
                areas: state.areas,
                selectedAreaId: state.selectedAreaId,
                onSelected: onAreaSelected,
                onManageAreasTap: () => _showComingSoon(context, 'Khu vực'),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              if (state.areas.isEmpty)
                const _EmptyState(
                  icon: Icons.layers_clear_outlined,
                  title: 'Chưa có khu vực',
                  message: 'Cửa hàng này chưa có khu vực để cài đặt bàn.',
                )
              else
                for (final section in sections) ...[
                  _SettingsAreaSection(
                    section: section,
                    canUpdateArea: access.canUpdateArea,
                    canCreateTable: access.canCreateTable,
                    canUpdateTable: access.canUpdateTable,
                    onEditArea: (area) => _showAreaForm(context, access, area),
                    onAddTable: (area) =>
                        _showCreateTableForm(context, access, [area], area),
                    onEditTable: (table) => _showUpdateTableForm(
                      context,
                      access,
                      state.areas,
                      table,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                ],
            ],
          ),
        ),
        Positioned(
          right: AppConstants.spacingMd,
          bottom: AppConstants.spacingLg,
          child: _AddTableFab(
            isEnabled: access.canCreateTable && state.areas.isNotEmpty,
            onPressed: () {
              final selectedArea = state.selectedAreaId == null
                  ? null
                  : state.areas.firstWhere(
                      (area) => area.id == state.selectedAreaId,
                    );
              _showCreateTableForm(context, access, state.areas, selectedArea);
            },
          ),
        ),
        if (state.status == TableManagementStatus.loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  List<TableAreaGroup> _buildSections(TableManagementState state) {
    final areas = state.selectedAreaId == null
        ? state.areas
        : state.areas.where((area) => area.id == state.selectedAreaId).toList();
    final groupsByAreaId = {
      for (final group in state.visibleGroups) group.area.id: group,
    };

    return areas.map((area) {
      final group = groupsByAreaId[area.id];
      return TableAreaGroup(area: area, tables: group?.tables ?? const []);
    }).toList();
  }
}

class _SettingsAreaSection extends StatelessWidget {
  final TableAreaGroup section;
  final bool canUpdateArea;
  final bool canCreateTable;
  final bool canUpdateTable;
  final ValueChanged<Area> onEditArea;
  final ValueChanged<Area> onAddTable;
  final ValueChanged<DiningTable> onEditTable;

  const _SettingsAreaSection({
    required this.section,
    required this.canUpdateArea,
    required this.canCreateTable,
    required this.canUpdateTable,
    required this.onEditArea,
    required this.onAddTable,
    required this.onEditTable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                section.area.name,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              key: Key('settings_edit_area_${section.area.id}'),
              tooltip: 'Sửa khu vực',
              onPressed: canUpdateArea ? () => onEditArea(section.area) : null,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppConstants.spacingMd,
            crossAxisSpacing: AppConstants.spacingMd,
            childAspectRatio: 1.28,
          ),
          itemCount: section.tables.length + 1,
          itemBuilder: (context, index) {
            if (index == section.tables.length) {
              return _SettingsAddTableCard(
                isEnabled: canCreateTable,
                onTap: () => onAddTable(section.area),
              );
            }

            final table = section.tables[index];
            return _SettingsTableCard(
              table: table,
              canUpdate: canUpdateTable,
              onEdit: () => onEditTable(table),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsTableCard extends StatelessWidget {
  final DiningTable table;
  final bool canUpdate;
  final VoidCallback onEdit;

  const _SettingsTableCard({
    required this.table,
    required this.canUpdate,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    table.name,
                    style: AppTextStyles.labelSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: Key('settings_edit_table_${table.id}'),
                  tooltip: 'Sửa bàn',
                  onPressed: canUpdate ? onEdit : null,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.table_restaurant_rounded,
              color: AppColors.textDisabled,
              size: 38,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _SettingsAddTableCard extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onTap;

  const _SettingsAddTableCard({required this.isEnabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? AppColors.primary : AppColors.textDisabled;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: isEnabled ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isEnabled ? AppColors.primaryLight : AppColors.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: color, size: 28),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Thêm bàn mới',
              style: AppTextStyles.labelSm.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTableFab extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const _AddTableFab({required this.isEnabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      key: const Key('settings_add_table_fab'),
      onPressed: isEnabled ? onPressed : null,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Thêm bàn mới'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingLg,
          vertical: AppConstants.spacingSm,
        ),
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onAction;
  final String actionLabel;

  const _BlockedView({
    required this.title,
    required this.message,
    required this.onAction,
    required this.actionLabel,
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
            const Icon(
              Icons.visibility_off_outlined,
              color: AppColors.textMuted,
              size: 44,
            ),
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
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 42),
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

Future<void> _showAreaForm(
  BuildContext context,
  TableManagementAccess access,
  Area area,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final notifier = container.read(
    tableManagementNotifierProvider(access).notifier,
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

Future<void> _showCreateTableForm(
  BuildContext context,
  TableManagementAccess access,
  List<Area> areas,
  Area? initialArea,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final notifier = container.read(
    tableManagementNotifierProvider(access).notifier,
  );

  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return TableFormBottomSheet(
        areas: areas,
        initialArea: initialArea,
        allowAreaSelection: initialArea == null,
        onSubmit: (area, name, capacity) {
          return notifier.createTable(
            areaId: area.id,
            name: name,
            capacity: capacity,
          );
        },
      );
    },
  );

  if (created == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Thêm bàn thành công!')));
  }
}

Future<void> _showUpdateTableForm(
  BuildContext context,
  TableManagementAccess access,
  List<Area> areas,
  DiningTable table,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final notifier = container.read(
    tableManagementNotifierProvider(access).notifier,
  );
  final initialArea = areas.firstWhere((area) => area.id == table.areaId);

  final updated = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return TableFormBottomSheet(
        areas: areas,
        initialArea: initialArea,
        table: table,
        allowAreaSelection: true,
        showDeleteAction: true,
        onDeleteTap: () => _showComingSoon(context, 'Xóa bàn'),
        onSubmit: (area, name, capacity) {
          return notifier.updateTable(
            tableId: table.id,
            areaId: area.id,
            name: name,
            capacity: capacity,
          );
        },
      );
    },
  );

  if (updated == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật thông tin bàn thành công!')),
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}
