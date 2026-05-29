import '../../domain/entities/area.dart';
import '../../domain/entities/table_area_group.dart';
import '../../domain/entities/table_status.dart';

enum TableManagementStatus { initial, loading, ready, forbidden, error }

enum TableStatusFilter { all, occupied, available }

class TableManagementAccess {
  final int storeId;
  final bool canViewAreas;
  final bool canViewTables;
  final bool canCreateArea;
  final bool canUpdateArea;
  final bool canDeleteArea;
  final bool canCreateTable;
  final bool canUpdateTable;

  const TableManagementAccess({
    required this.storeId,
    required this.canViewAreas,
    required this.canViewTables,
    required this.canCreateArea,
    required this.canUpdateArea,
    required this.canDeleteArea,
    required this.canCreateTable,
    required this.canUpdateTable,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TableManagementAccess &&
            runtimeType == other.runtimeType &&
            storeId == other.storeId &&
            canViewAreas == other.canViewAreas &&
            canViewTables == other.canViewTables &&
            canCreateArea == other.canCreateArea &&
            canUpdateArea == other.canUpdateArea &&
            canDeleteArea == other.canDeleteArea &&
            canCreateTable == other.canCreateTable &&
            canUpdateTable == other.canUpdateTable;
  }

  @override
  int get hashCode => Object.hash(
    storeId,
    canViewAreas,
    canViewTables,
    canCreateArea,
    canUpdateArea,
    canDeleteArea,
    canCreateTable,
    canUpdateTable,
  );
}

class TableManagementState {
  final TableManagementStatus status;
  final List<Area> areas;
  final List<TableAreaGroup> tableGroups;
  final int? selectedAreaId;
  final TableStatusFilter statusFilter;
  final bool canViewTables;
  final String? errorMessage;

  const TableManagementState({
    required this.status,
    this.areas = const [],
    this.tableGroups = const [],
    this.selectedAreaId,
    this.statusFilter = TableStatusFilter.all,
    this.canViewTables = false,
    this.errorMessage,
  });

  const TableManagementState.initial()
    : status = TableManagementStatus.initial,
      areas = const [],
      tableGroups = const [],
      selectedAreaId = null,
      statusFilter = TableStatusFilter.all,
      canViewTables = false,
      errorMessage = null;

  bool get isLoading =>
      status == TableManagementStatus.initial ||
      status == TableManagementStatus.loading;

  bool get hasSelectedArea => selectedAreaId != null;

  int get availableTableCount {
    return tableGroups.fold<int>(
      0,
      (count, group) =>
          count +
          group.tables
              .where((table) => table.status == TableStatus.available)
              .length,
    );
  }

  List<TableAreaGroup> get visibleGroups {
    final filteredGroups = selectedAreaId == null
        ? tableGroups
        : tableGroups
              .where((group) => group.area.id == selectedAreaId)
              .toList();

    if (statusFilter == TableStatusFilter.all) {
      return filteredGroups;
    }

    return filteredGroups
        .map((group) {
          final filteredTables = group.tables.where((table) {
            return switch (statusFilter) {
              TableStatusFilter.all => true,
              TableStatusFilter.occupied =>
                table.status == TableStatus.occupied,
              TableStatusFilter.available =>
                table.status == TableStatus.available,
            };
          }).toList();

          return TableAreaGroup(area: group.area, tables: filteredTables);
        })
        .where((group) => group.tables.isNotEmpty)
        .toList();
  }

  TableManagementState copyWith({
    TableManagementStatus? status,
    List<Area>? areas,
    List<TableAreaGroup>? tableGroups,
    int? selectedAreaId,
    bool clearSelectedArea = false,
    TableStatusFilter? statusFilter,
    bool? canViewTables,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TableManagementState(
      status: status ?? this.status,
      areas: areas ?? this.areas,
      tableGroups: tableGroups ?? this.tableGroups,
      selectedAreaId: clearSelectedArea
          ? null
          : (selectedAreaId ?? this.selectedAreaId),
      statusFilter: statusFilter ?? this.statusFilter,
      canViewTables: canViewTables ?? this.canViewTables,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
