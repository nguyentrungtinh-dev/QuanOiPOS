import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/area.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/dining_table.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/table_area_group.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/table_status.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/repositories/table_management_repository.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/create_area_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/delete_area_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/load_areas_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/load_table_groups_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/update_area_display_order_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/update_area_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/pages/table_management_page.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/providers/table_management_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('blocks direct access without AREA.VIEW', (tester) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền xem quản lý bàn'), findsOneWidget);
    expect(tableRepository.loadAreasCallCount, 0);
    expect(tableRepository.loadTableGroupsCallCount, 0);
  });

  testWidgets('loads areas but does not fetch tables without TABLE.VIEW', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [StorePermission(permissionId: 2, code: 'AREA.VIEW')],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Bên trong'), findsWidgets);
    expect(find.text('Bạn chưa có quyền xem danh sách bàn'), findsWidgets);
    expect(tableRepository.loadAreasCallCount, 1);
    expect(tableRepository.loadTableGroupsCallCount, 0);
  });

  testWidgets('renders tables and filters by status', (tester) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
        StorePermission(permissionId: 4, code: 'TABLE.CREATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Bàn 1'), findsOneWidget);
    expect(find.text('Bàn 2'), findsOneWidget);
    expect(find.text('Thêm bàn mới'), findsWidgets);
    expect(tableRepository.loadTableGroupsCallCount, 1);

    await tester.tap(find.byKey(const Key('table_status_filter_occupied')));
    await tester.pumpAndSettle();

    expect(find.text('Bàn 1'), findsNothing);
    expect(find.text('Bàn 2'), findsOneWidget);
  });

  testWidgets('selecting an area refetches tables with areaId', (tester) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sân vườn'));
    await tester.pumpAndSettle();

    expect(tableRepository.lastAreaId, 7);
    expect(find.text('Bàn 3'), findsOneWidget);
    expect(find.text('Bàn 1'), findsNothing);
  });

  testWidgets(
    'area row uses separate management button and all chip has no icon',
    (tester) async {
      final tableRepository = _FakeTableManagementRepository();

      await _pumpPage(
        tester,
        permissions: const [
          StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        ],
        tableRepository: tableRepository,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manage_areas_button')), findsOneWidget);
      expect(find.byKey(const Key('area_chips_scroll_view')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('area_chips_scroll_view')),
          matching: find.byKey(const Key('manage_areas_button')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(OutlinedButton, 'Tất cả'),
          matching: find.byIcon(Icons.grid_view_rounded),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('area management sheet renders reference-like header', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 5, code: 'AREA.CREATE'),
        StorePermission(permissionId: 6, code: 'AREA.UPDATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_areas_button')));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('area_management_sheet'));
    expect(
      find.descendant(of: sheet, matching: find.text('Chỉnh sửa')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Khu vực')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byKey(const Key('close_area_management_button')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byKey(const Key('area_management_search_field')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byKey(const Key('add_area_button')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('area management bottom sheet searches areas', (tester) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [StorePermission(permissionId: 2, code: 'AREA.VIEW')],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_areas_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('area_management_search_field')),
      'sân',
    );
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('area_management_sheet'));
    expect(
      find.descendant(of: sheet, matching: find.text('Sân vườn')),
      findsWidgets,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Bên trong')),
      findsNothing,
    );
  });

  testWidgets('area action buttons are disabled by PBAC', (tester) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [StorePermission(permissionId: 2, code: 'AREA.VIEW')],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_areas_button')));
    await tester.pumpAndSettle();

    final addButton = tester.widget<IconButton>(
      find.byKey(const Key('add_area_button')),
    );
    final editButton = tester.widget<TextButton>(
      find.byKey(const Key('edit_areas_button')),
    );

    expect(addButton.onPressed, isNull);
    expect(editButton.onPressed, isNull);
  });

  testWidgets('area form validates required name', (tester) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 5, code: 'AREA.CREATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_areas_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_area_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('area_form_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tên khu vực'), findsOneWidget);
    expect(tableRepository.createAreaCallCount, 0);
  });

  testWidgets('creating area calls API and reloads data', (tester) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 5, code: 'AREA.CREATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_areas_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_area_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('area_form_name_field')),
      'Phòng VIP',
    );
    await tester.enterText(
      find.byKey(const Key('area_form_description_field')),
      'Khu vực riêng',
    );
    await tester.tap(find.byKey(const Key('area_form_submit_button')));
    await tester.pumpAndSettle();

    expect(tableRepository.createAreaCallCount, 1);
    expect(tableRepository.loadAreasCallCount, greaterThan(1));
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required List<StorePermission> permissions,
  required _FakeTableManagementRepository tableRepository,
}) async {
  final workspaceRepository = _FakeWorkspaceRepository(permissions);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        loadStoreAccessContextUseCaseProvider.overrideWithValue(
          LoadStoreAccessContextUseCase(workspaceRepository),
        ),
        loadMyStoresUseCaseProvider.overrideWithValue(
          LoadMyStoresUseCase(workspaceRepository),
        ),
        loadAreasUseCaseProvider.overrideWithValue(
          LoadAreasUseCase(tableRepository),
        ),
        loadTableGroupsUseCaseProvider.overrideWithValue(
          LoadTableGroupsUseCase(tableRepository),
        ),
        createAreaUseCaseProvider.overrideWithValue(
          CreateAreaUseCase(tableRepository),
        ),
        updateAreaUseCaseProvider.overrideWithValue(
          UpdateAreaUseCase(tableRepository),
        ),
        updateAreaDisplayOrderUseCaseProvider.overrideWithValue(
          UpdateAreaDisplayOrderUseCase(tableRepository),
        ),
        deleteAreaUseCaseProvider.overrideWithValue(
          DeleteAreaUseCase(tableRepository),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TableManagementPage(storeId: 5),
      ),
    ),
  );
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<StorePermission> permissions;

  const _FakeWorkspaceRepository(this.permissions);

  @override
  Future<List<Store>> loadMyStores() async {
    return const [_store];
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    return _store;
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return permissions;
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    return StoreAccessContext(
      store: await loadStoreById(storeId),
      permissions: await loadMyStorePermissions(storeId),
    );
  }
}

class _FakeTableManagementRepository implements TableManagementRepository {
  int loadAreasCallCount = 0;
  int loadTableGroupsCallCount = 0;
  int createAreaCallCount = 0;
  int updateAreaCallCount = 0;
  int updateAreaDisplayOrderCallCount = 0;
  int deleteAreaCallCount = 0;
  int? lastAreaId;

  @override
  Future<List<Area>> loadAreas(int storeId) async {
    loadAreasCallCount += 1;
    return _areas;
  }

  @override
  Future<List<TableAreaGroup>> loadTableGroups({
    required int storeId,
    int? areaId,
  }) async {
    loadTableGroupsCallCount += 1;
    lastAreaId = areaId;

    if (areaId == null) {
      return _tableGroups;
    }

    return _tableGroups.where((group) => group.area.id == areaId).toList();
  }

  @override
  Future<Area> createArea({
    required int storeId,
    required String name,
    required String description,
  }) async {
    createAreaCallCount += 1;
    return Area(
      id: 99,
      storeId: storeId,
      name: name,
      description: description,
      displayOrder: 3,
      isActive: true,
      isDeleted: false,
    );
  }

  @override
  Future<Area> updateArea({
    required int areaId,
    required String name,
    required String description,
  }) async {
    updateAreaCallCount += 1;
    return Area(
      id: areaId,
      storeId: 5,
      name: name,
      description: description,
      displayOrder: 1,
      isActive: true,
      isDeleted: false,
    );
  }

  @override
  Future<Area> updateAreaDisplayOrder({
    required int areaId,
    required int displayOrder,
  }) async {
    updateAreaDisplayOrderCallCount += 1;
    return _areas
        .firstWhere((area) => area.id == areaId)
        .copyWithDisplayOrder(displayOrder);
  }

  @override
  Future<void> deleteArea(int areaId) async {
    deleteAreaCallCount += 1;
  }
}

const _store = Store(
  id: 5,
  ownerAccountId: 8,
  storeName: 'FPT Shipper Vip',
  phone: '0123456789',
  address: 'Gần Đại Học FPT',
  status: StoreStatus.active,
  isDeleted: false,
);

const _insideArea = Area(
  id: 6,
  storeId: 5,
  name: 'Bên trong',
  description: '',
  displayOrder: 1,
  isActive: true,
  isDeleted: false,
);

const _gardenArea = Area(
  id: 7,
  storeId: 5,
  name: 'Sân vườn',
  description: '',
  displayOrder: 2,
  isActive: true,
  isDeleted: false,
);

const _areas = [_insideArea, _gardenArea];

const _tableGroups = [
  TableAreaGroup(
    area: _insideArea,
    tables: [
      DiningTable(
        id: 3,
        storeId: 5,
        areaId: 6,
        name: 'Bàn 1',
        capacity: 4,
        status: TableStatus.available,
        isDeleted: false,
      ),
      DiningTable(
        id: 4,
        storeId: 5,
        areaId: 6,
        name: 'Bàn 2',
        capacity: 2,
        status: TableStatus.occupied,
        isDeleted: false,
      ),
    ],
  ),
  TableAreaGroup(
    area: _gardenArea,
    tables: [
      DiningTable(
        id: 5,
        storeId: 5,
        areaId: 7,
        name: 'Bàn 3',
        capacity: 6,
        status: TableStatus.reserved,
        isDeleted: false,
      ),
    ],
  ),
];

extension on Area {
  Area copyWithDisplayOrder(int displayOrder) {
    return Area(
      id: id,
      storeId: storeId,
      name: name,
      description: description,
      displayOrder: displayOrder,
      isActive: isActive,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      isDeleted: isDeleted,
    );
  }
}
