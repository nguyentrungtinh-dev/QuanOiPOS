import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/area.dart';
import '../../domain/entities/table_area_group.dart';
import '../providers/table_management_providers.dart';
import 'table_management_state.dart';

class TableManagementNotifier
    extends
        AutoDisposeFamilyNotifier<TableManagementState, TableManagementAccess> {
  late final TableManagementAccess _access;
  bool _initialLoadStarted = false;
  Future<void> _areaOrderSaveQueue = Future<void>.value();

  @override
  TableManagementState build(TableManagementAccess arg) {
    _access = arg;
    Future.microtask(load);
    return TableManagementState.initial().copyWith(
      canViewTables: arg.canViewTables,
    );
  }

  Future<void> load() async {
    if (_initialLoadStarted && state.status == TableManagementStatus.loading) {
      return;
    }

    _initialLoadStarted = true;

    if (!_access.canViewAreas) {
      state = state.copyWith(
        status: TableManagementStatus.forbidden,
        canViewTables: _access.canViewTables,
        errorMessage: 'Bạn chưa có quyền xem quản lý bàn',
      );
      return;
    }

    state = state.copyWith(
      status: TableManagementStatus.loading,
      canViewTables: _access.canViewTables,
      clearError: true,
    );

    try {
      final areas = await ref.read(loadAreasUseCaseProvider)(_access.storeId);
      final tableGroups = _access.canViewTables
          ? await ref.read(loadTableGroupsUseCaseProvider)(
              storeId: _access.storeId,
            )
          : const <TableAreaGroup>[];

      state = state.copyWith(
        status: TableManagementStatus.ready,
        areas: areas,
        tableGroups: tableGroups,
        canViewTables: _access.canViewTables,
        clearError: true,
      );
      _areaOrderSaveQueue = Future<void>.value();
    } catch (error) {
      state = state.copyWith(
        status: TableManagementStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> createArea({
    required String name,
    required String description,
  }) async {
    _ensureAllowed(_access.canCreateArea, 'Bạn chưa có quyền thêm khu vực');

    await ref.read(createAreaUseCaseProvider)(
      storeId: _access.storeId,
      name: name,
      description: description,
    );
    await load();
  }

  Future<void> createTable({
    required int areaId,
    required String name,
    required int capacity,
  }) async {
    _ensureAllowed(_access.canCreateTable, 'Bạn chưa có quyền thêm bàn');

    await ref.read(createTableUseCaseProvider)(
      storeId: _access.storeId,
      areaId: areaId,
      name: name,
      capacity: capacity,
    );
    await load();
  }

  Future<void> updateTable({
    required int tableId,
    required int areaId,
    required String name,
    required int capacity,
  }) async {
    _ensureAllowed(_access.canUpdateTable, 'Bạn chưa có quyền cập nhật bàn');

    await ref.read(updateTableUseCaseProvider)(
      tableId: tableId,
      areaId: areaId,
      name: name,
      capacity: capacity,
    );
    await load();
  }

  Future<void> updateArea({
    required int areaId,
    required String name,
    required String description,
  }) async {
    _ensureAllowed(
      _access.canUpdateArea,
      'Bạn chưa có quyền chỉnh sửa khu vực',
    );

    await ref.read(updateAreaUseCaseProvider)(
      areaId: areaId,
      name: name,
      description: description,
    );
    await load();
  }

  Future<void> deleteArea(int areaId) async {
    _ensureAllowed(_access.canDeleteArea, 'Bạn chưa có quyền xóa khu vực');

    await ref.read(deleteAreaUseCaseProvider)(areaId);
    if (state.selectedAreaId == areaId) {
      state = state.copyWith(clearSelectedArea: true);
    }
    await load();
  }

  Future<void> reorderAreas(List<Area> reorderedAreas) async {
    _ensureAllowed(
      _access.canUpdateArea,
      'Bạn chưa có quyền cập nhật thứ tự khu vực',
    );

    final oldOrdersById = {
      for (final area in state.areas) area.id: area.displayOrder,
    };
    final normalizedAreas = <Area>[];
    final changedAreas = <Area>[];

    for (var index = 0; index < reorderedAreas.length; index += 1) {
      final nextOrder = index + 1;
      final area = reorderedAreas[index];
      final normalizedArea = _copyAreaWithDisplayOrder(area, nextOrder);
      normalizedAreas.add(normalizedArea);

      if (oldOrdersById[area.id] != nextOrder) {
        changedAreas.add(normalizedArea);
      }
    }

    final normalizedAreasById = {
      for (final area in normalizedAreas) area.id: area,
    };
    final syncedTableGroups = state.tableGroups.map((group) {
      final area = normalizedAreasById[group.area.id];
      if (area == null) {
        return group;
      }

      return TableAreaGroup(area: area, tables: group.tables);
    }).toList();

    state = state.copyWith(
      areas: normalizedAreas,
      tableGroups: syncedTableGroups,
    );

    if (changedAreas.isEmpty) {
      return;
    }

    final areasToSave = List<Area>.unmodifiable(normalizedAreas);
    final saveOperation = _areaOrderSaveQueue.then((_) async {
      for (final area in areasToSave) {
        await ref.read(updateAreaDisplayOrderUseCaseProvider)(
          areaId: area.id,
          displayOrder: area.displayOrder,
        );
      }
    });
    _areaOrderSaveQueue = saveOperation.catchError((Object _) {});

    return saveOperation;
  }

  void selectArea(int? areaId) {
    if (state.selectedAreaId == areaId) {
      return;
    }

    state = state.copyWith(
      selectedAreaId: areaId,
      clearSelectedArea: areaId == null,
    );
  }

  void setStatusFilter(TableStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _ensureAllowed(bool isAllowed, String message) {
    if (!isAllowed) {
      throw Exception(message);
    }
  }

  Area _copyAreaWithDisplayOrder(Area area, int displayOrder) {
    return Area(
      id: area.id,
      storeId: area.storeId,
      name: area.name,
      description: area.description,
      displayOrder: displayOrder,
      isActive: area.isActive,
      createdAt: area.createdAt,
      createdBy: area.createdBy,
      updatedAt: area.updatedAt,
      updatedBy: area.updatedBy,
      isDeleted: area.isDeleted,
    );
  }
}
