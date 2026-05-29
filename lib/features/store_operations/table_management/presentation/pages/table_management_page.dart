import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/entities/table_area_group.dart';
import '../controllers/table_management_state.dart';
import '../providers/table_management_providers.dart';
import '../widgets/area_filter_chips.dart';
import '../widgets/area_management_bottom_sheet.dart';
import '../widgets/area_table_section.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/table_management_header.dart';
import '../widgets/table_status_tabs.dart';

class TableManagementPage extends ConsumerWidget {
  final int storeId;

  const TableManagementPage({super.key, required this.storeId});

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
            onAction: () => context.goNamed(RouteNames.myStores),
            actionLabel: 'Về danh sách cửa hàng',
          ),
          StoreAccessStatus.error => _ErrorView(
            message: accessState.errorMessage ?? 'Không thể tải quyền cửa hàng',
            onRetry: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready => _AccessReadyView(
            storeId: storeId,
            accessState: accessState,
          ),
        },
      ),
    );
  }
}

class _AccessReadyView extends ConsumerWidget {
  final int storeId;
  final StoreAccessState accessState;

  const _AccessReadyView({required this.storeId, required this.accessState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!accessState.can(AppPermissionCodes.areaView)) {
      return _BlockedView(
        icon: Icons.visibility_off_outlined,
        title: 'Bạn chưa có quyền xem quản lý bàn',
        message: 'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
        onAction: () => context.goNamed(
          RouteNames.storeOverview,
          pathParameters: {'storeId': storeId.toString()},
        ),
        actionLabel: 'Về tổng quan',
      );
    }

    final access = TableManagementAccess(
      storeId: storeId,
      canViewAreas: accessState.can(AppPermissionCodes.areaView),
      canViewTables: accessState.can(AppPermissionCodes.tableView),
      canCreateArea: accessState.can(AppPermissionCodes.areaCreate),
      canUpdateArea: accessState.can(AppPermissionCodes.areaUpdate),
      canDeleteArea: accessState.can(AppPermissionCodes.areaDelete),
    );
    final state = ref.watch(tableManagementNotifierProvider(access));
    final notifier = ref.read(tableManagementNotifierProvider(access).notifier);

    return Column(
      children: [
        TableManagementHeader(
          onBack: () => context.goNamed(
            RouteNames.storeOverview,
            pathParameters: {'storeId': storeId.toString()},
          ),
          onOrdersTap: () => _showComingSoon(context, 'Đơn hàng'),
          onMoreTap: () => _showComingSoon(context, 'Thêm'),
        ),
        TableStatusTabs(
          selectedFilter: state.statusFilter,
          availableCount: state.availableTableCount,
          onChanged: notifier.setStatusFilter,
        ),
        Expanded(
          child: switch (state.status) {
            TableManagementStatus.initial ||
            TableManagementStatus.loading => const _LoadingView(),
            TableManagementStatus.forbidden => _BlockedView(
              icon: Icons.visibility_off_outlined,
              title: 'Bạn chưa có quyền xem quản lý bàn',
              message:
                  state.errorMessage ??
                  'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
              onAction: () => context.goNamed(
                RouteNames.storeOverview,
                pathParameters: {'storeId': storeId.toString()},
              ),
              actionLabel: 'Về tổng quan',
            ),
            TableManagementStatus.error => _ErrorView(
              message: state.errorMessage ?? 'Không thể tải quản lý bàn',
              onRetry: notifier.load,
            ),
            TableManagementStatus.ready => _ReadyContent(
              state: state,
              canCreateTable: accessState.can(AppPermissionCodes.tableCreate),
              access: access,
              onRefresh: notifier.load,
              onAreaSelected: notifier.selectArea,
              onAddTableTap: () => _showComingSoon(context, 'Thêm bàn mới'),
              onTableTap: (table) => _showComingSoon(context, table.name),
            ),
          },
        ),
      ],
    );
  }
}

class _ReadyContent extends StatelessWidget {
  final TableManagementState state;
  final bool canCreateTable;
  final TableManagementAccess access;
  final Future<void> Function() onRefresh;
  final ValueChanged<int?> onAreaSelected;
  final VoidCallback onAddTableTap;
  final ValueChanged<DiningTable> onTableTap;

  const _ReadyContent({
    required this.state,
    required this.canCreateTable,
    required this.access,
    required this.onRefresh,
    required this.onAreaSelected,
    required this.onAddTableTap,
    required this.onTableTap,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(state);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingMd,
          AppConstants.spacingMd,
          AppConstants.spacingMd,
          AppConstants.spacingXxl,
        ),
        children: [
          AreaFilterChips(
            areas: state.areas,
            selectedAreaId: state.selectedAreaId,
            onSelected: onAreaSelected,
            onManageAreasTap: () => _showAreaManagement(context, access),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          QuickActionGrid(
            onTakeAwayTap: () => _showComingSoon(context, 'Mang về'),
            onDeliveryTap: () => _showComingSoon(context, 'Giao hàng'),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          if (state.areas.isEmpty)
            const _EmptyState(
              icon: Icons.layers_clear_outlined,
              title: 'Chưa có khu vực',
              message: 'Cửa hàng này chưa có khu vực để hiển thị.',
            )
          else if (sections.isEmpty)
            const _EmptyState(
              icon: Icons.table_restaurant_outlined,
              title: 'Chưa có bàn phù hợp',
              message: 'Hãy thử đổi bộ lọc trạng thái hoặc khu vực.',
            )
          else
            for (final section in sections) ...[
              AreaTableSection(
                area: section.area,
                tables: section.tables,
                canViewTables: state.canViewTables,
                canCreateTable: canCreateTable,
                onAddTableTap: onAddTableTap,
                onTableTap: onTableTap,
              ),
              const SizedBox(height: AppConstants.spacingLg),
            ],
        ],
      ),
    );
  }

  List<TableAreaGroup> _buildSections(TableManagementState state) {
    final areas = state.selectedAreaId == null
        ? state.areas
        : state.areas.where((area) => area.id == state.selectedAreaId).toList();

    if (!state.canViewTables) {
      return areas
          .map((area) => TableAreaGroup(area: area, tables: const []))
          .toList();
    }

    final groupByAreaId = {
      for (final group in state.visibleGroups) group.area.id: group,
    };

    return areas
        .map((area) {
          final group = groupByAreaId[area.id];
          return TableAreaGroup(area: area, tables: group?.tables ?? const []);
        })
        .where((group) {
          if (state.statusFilter == TableStatusFilter.all) {
            return true;
          }

          return group.tables.isNotEmpty;
        })
        .toList();
  }
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onAction;
  final String actionLabel;

  const _BlockedView({
    required this.icon,
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

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}

Future<void> _showAreaManagement(
  BuildContext context,
  TableManagementAccess access,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.72,
        child: AreaManagementBottomSheet(access: access),
      );
    },
  );
}
