import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/area.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/dining_table.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/table_area_group.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/table_status.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/repositories/table_management_repository.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/create_area_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/create_table_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/delete_area_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/load_areas_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/load_table_groups_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/update_area_display_order_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/update_area_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/update_table_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/controllers/table_management_state.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/pages/table_management_page.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/pages/table_settings_page.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/providers/table_management_providers.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/widgets/add_table_tile.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
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

  testWidgets('selecting an area filters locally without refetching', (
    tester,
  ) async {
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

    final initialLoadCount = tableRepository.loadTableGroupsCallCount;
    expect(initialLoadCount, 1);
    expect(tableRepository.lastAreaId, isNull);

    await tester.tap(find.text('Sân vườn'));
    await tester.pumpAndSettle();

    expect(tableRepository.loadTableGroupsCallCount, initialLoadCount);
    expect(tableRepository.lastAreaId, isNull);
    expect(find.text('Bàn 3'), findsOneWidget);
    expect(find.text('Bàn 1'), findsNothing);
  });

  test(
    'manual reload after selecting an area fetches full table groups',
    () async {
      final tableRepository = _FakeTableManagementRepository();
      final workspaceRepository = _FakeWorkspaceRepository(const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
      ]);
      final container = ProviderContainer(
        overrides: _overrides(workspaceRepository, tableRepository),
      );
      addTearDown(container.dispose);

      const access = TableManagementAccess(
        storeId: 5,
        canViewAreas: true,
        canViewTables: true,
        canCreateArea: false,
        canUpdateArea: false,
        canDeleteArea: false,
        canCreateTable: false,
        canUpdateTable: false,
      );
      final provider = tableManagementNotifierProvider(access);

      container.read(provider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(tableRepository.loadTableGroupsCallCount, 1);
      expect(tableRepository.lastAreaId, isNull);

      container.read(provider.notifier).selectArea(7);
      await container.read(provider.notifier).load();

      expect(tableRepository.loadTableGroupsCallCount, 2);
      expect(tableRepository.lastAreaId, isNull);
      expect(container.read(provider).selectedAreaId, 7);
    },
  );

  testWidgets('more menu opens when user has area and table CRUD permissions', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'AREA.CREATE'),
        StorePermission(permissionId: 4, code: 'TABLE.UPDATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('table_header_more_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('table_header_edit_action')), findsOneWidget);
    expect(
      find.byKey(const Key('table_header_download_qr_action')),
      findsOneWidget,
    );
    expect(find.text('Sửa'), findsOneWidget);
    expect(find.text('Tải QR bàn'), findsOneWidget);
  });

  testWidgets(
    'more menu stays closed without area and table CRUD permissions',
    (tester) async {
      final tableRepository = _FakeTableManagementRepository();

      await _pumpPage(
        tester,
        permissions: const [
          StorePermission(permissionId: 2, code: 'AREA.VIEW'),
          StorePermission(permissionId: 3, code: 'TABLE.UPDATE'),
        ],
        tableRepository: tableRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('table_header_more_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('table_header_edit_action')), findsNothing);
      expect(
        find.byKey(const Key('table_header_download_qr_action')),
        findsNothing,
      );
      expect(find.text('Sửa'), findsNothing);
      expect(find.text('Tải QR bàn'), findsNothing);
    },
  );

  testWidgets('download qr menu action shows placeholder feedback', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'AREA.UPDATE'),
        StorePermission(permissionId: 4, code: 'TABLE.DELETE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('table_header_more_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tải QR bàn'));
    await tester.pumpAndSettle();

    expect(find.text('Tải QR bàn sẽ được triển khai sau'), findsOneWidget);
    expect(
      find.byKey(const Key('table_header_download_qr_action')),
      findsNothing,
    );
  });

  testWidgets('more menu edit navigates to table settings page', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpRoutedPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'AREA.UPDATE'),
        StorePermission(permissionId: 4, code: 'TABLE.VIEW'),
        StorePermission(permissionId: 5, code: 'TABLE.UPDATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('table_header_more_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt bàn'), findsOneWidget);
    expect(find.byKey(const Key('settings_edit_table_3')), findsOneWidget);
  });

  testWidgets('settings page renders edit actions by PBAC', (tester) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpSettingsPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
        StorePermission(permissionId: 4, code: 'AREA.UPDATE'),
        StorePermission(permissionId: 5, code: 'TABLE.UPDATE'),
        StorePermission(permissionId: 6, code: 'TABLE.CREATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt bàn'), findsOneWidget);
    expect(find.byKey(const Key('settings_edit_area_6')), findsOneWidget);
    expect(find.byKey(const Key('settings_edit_table_3')), findsOneWidget);
    expect(find.byKey(const Key('settings_add_table_fab')), findsOneWidget);

    final tableEditButton = tester.widget<IconButton>(
      find.byKey(const Key('settings_edit_table_3')),
    );
    expect(tableEditButton.onPressed, isNotNull);
  });

  testWidgets('settings manage areas button opens area management sheet', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpSettingsPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'AREA.CREATE'),
        StorePermission(permissionId: 4, code: 'AREA.UPDATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_areas_button')));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('area_management_sheet'));
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Khu vực')),
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
    expect(find.text('Khu vực sẽ được triển khai sau'), findsNothing);
  });

  testWidgets(
    'settings area management sheet disables actions without CRUD permissions',
    (tester) async {
      final tableRepository = _FakeTableManagementRepository();

      await _pumpSettingsPage(
        tester,
        permissions: const [
          StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        ],
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

      expect(find.byKey(const Key('area_management_sheet')), findsOneWidget);
      expect(addButton.onPressed, isNull);
      expect(editButton.onPressed, isNull);
    },
  );

  testWidgets('settings page blocks table edit without TABLE.UPDATE', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpSettingsPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    final tableEditButton = tester.widget<IconButton>(
      find.byKey(const Key('settings_edit_table_3')),
    );
    expect(tableEditButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('settings_edit_table_3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('table_form_submit_button')), findsNothing);
  });

  testWidgets('settings table edit sheet updates table and reloads data', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpSettingsPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
        StorePermission(permissionId: 4, code: 'TABLE.UPDATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    final initialLoadCount = tableRepository.loadTableGroupsCallCount;

    await tester.tap(find.byKey(const Key('settings_edit_table_3')));
    await tester.pumpAndSettle();

    expect(find.text('Bàn tại "Bên trong"'), findsOneWidget);
    expect(find.byKey(const Key('table_form_delete_button')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('table_form_name_field')),
      'Bàn 10',
    );
    await tester.enterText(
      find.byKey(const Key('table_form_capacity_field')),
      '8',
    );
    await tester.tap(find.byKey(const Key('table_form_submit_button')));
    await tester.pumpAndSettle();

    expect(tableRepository.updateTableCallCount, 1);
    expect(tableRepository.lastUpdatedTableId, 3);
    expect(tableRepository.lastUpdatedTableAreaId, 6);
    expect(tableRepository.lastUpdatedTableName, 'Bàn 10');
    expect(tableRepository.lastUpdatedTableCapacity, 8);
    expect(
      tableRepository.loadTableGroupsCallCount,
      greaterThan(initialLoadCount),
    );
    expect(find.text('Cập nhật thông tin bàn thành công!'), findsOneWidget);
  });

  testWidgets('settings add fab uses area selector from all filter', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpSettingsPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
        StorePermission(permissionId: 4, code: 'TABLE.CREATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings_add_table_fab')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('table_form_area_select_field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('table_form_area_field')), findsNothing);
  });

  testWidgets('settings add fab prefills selected area', (tester) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpSettingsPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
        StorePermission(permissionId: 4, code: 'TABLE.CREATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sân vườn'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_add_table_fab')));
    await tester.pumpAndSettle();

    final areaField = tester.widget<TextFormField>(
      find.byKey(const Key('table_form_area_field')),
    );
    expect(areaField.initialValue, 'Sân vườn');
  });

  testWidgets('settings add fab is disabled without TABLE.CREATE', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpSettingsPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    final addButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('settings_add_table_fab')),
    );
    expect(addButton.onPressed, isNull);
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

  testWidgets('reordering areas saves in background without loading overlay', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository();

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 3, code: 'TABLE.VIEW'),
        StorePermission(permissionId: 6, code: 'AREA.UPDATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    final initialLoadAreasCount = tableRepository.loadAreasCallCount;
    final initialLoadTableGroupsCount =
        tableRepository.loadTableGroupsCallCount;

    await tester.tap(find.byKey(const Key('manage_areas_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_areas_button')));
    await tester.pumpAndSettle();

    final reorderableList = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderableList.onReorder(0, 2);
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('area_management_sheet'));
    final gardenArea = find
        .descendant(of: sheet, matching: find.text('Sân vườn'))
        .first;
    final insideArea = find
        .descendant(of: sheet, matching: find.text('Bên trong'))
        .first;

    expect(
      tester.getTopLeft(gardenArea).dy,
      lessThan(tester.getTopLeft(insideArea).dy),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tableRepository.updateAreaDisplayOrderCallCount, 2);
    expect(tableRepository.updateAreaDisplayOrderRequests, ['7:1', '6:2']);
    expect(tableRepository.loadAreasCallCount, initialLoadAreasCount);
    expect(
      tableRepository.loadTableGroupsCallCount,
      initialLoadTableGroupsCount,
    );
  });

  testWidgets('reorder area error shows snackbar without locking the list', (
    tester,
  ) async {
    final tableRepository = _FakeTableManagementRepository()
      ..failUpdateAreaDisplayOrder = true;

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 6, code: 'AREA.UPDATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_areas_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_areas_button')));
    await tester.pumpAndSettle();

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder(0, 2);
    await tester.pumpAndSettle();

    expect(find.text('Không thể lưu thứ tự khu vực'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('rapid area reorders queue display-order saves', (tester) async {
    final tableRepository = _FakeTableManagementRepository()
      ..holdUpdateAreaDisplayOrder = true;

    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 2, code: 'AREA.VIEW'),
        StorePermission(permissionId: 6, code: 'AREA.UPDATE'),
      ],
      tableRepository: tableRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_areas_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_areas_button')));
    await tester.pumpAndSettle();

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder(0, 2);
    await tester.pump();

    expect(tableRepository.updateAreaDisplayOrderRequests, ['7:1']);
    expect(tableRepository.updateAreaDisplayOrderCompleters, hasLength(1));

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder(0, 2);
    await tester.pump();

    expect(tableRepository.updateAreaDisplayOrderRequests, ['7:1']);

    await _completeDisplayOrderSave(tester, tableRepository, 0);
    expect(tableRepository.updateAreaDisplayOrderRequests, ['7:1', '6:2']);

    await _completeDisplayOrderSave(tester, tableRepository, 1);
    expect(tableRepository.updateAreaDisplayOrderRequests, [
      '7:1',
      '6:2',
      '6:1',
    ]);

    await _completeDisplayOrderSave(tester, tableRepository, 2);
    expect(tableRepository.updateAreaDisplayOrderRequests, [
      '7:1',
      '6:2',
      '6:1',
      '7:2',
    ]);

    await _completeDisplayOrderSave(tester, tableRepository, 3);
    await tester.pumpAndSettle();
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

  testWidgets('add table sheet prefills area and validates required fields', (
    tester,
  ) async {
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

    final addTableTile = await _scrollToFirstAddTableTile(tester);
    await tester.tap(addTableTile);
    await tester.pumpAndSettle();

    final areaField = tester.widget<TextFormField>(
      find.byKey(const Key('table_form_area_field')),
    );
    expect(areaField.initialValue, 'Bên trong');

    await tester.tap(find.byKey(const Key('table_form_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tên bàn'), findsOneWidget);
    expect(find.text('Vui lòng nhập số chỗ'), findsOneWidget);
    expect(tableRepository.createTableCallCount, 0);
  });

  testWidgets('creating table calls API with selected area and reloads data', (
    tester,
  ) async {
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

    final initialLoadCount = tableRepository.loadTableGroupsCallCount;

    final addTableTile = await _scrollToFirstAddTableTile(tester);
    await tester.tap(addTableTile);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('table_form_name_field')),
      'Bàn 9',
    );
    await tester.enterText(
      find.byKey(const Key('table_form_capacity_field')),
      '4',
    );
    await tester.tap(find.byKey(const Key('table_form_submit_button')));
    await tester.pumpAndSettle();

    expect(tableRepository.createTableCallCount, 1);
    expect(tableRepository.lastCreatedTableStoreId, 5);
    expect(tableRepository.lastCreatedTableAreaId, 6);
    expect(tableRepository.lastCreatedTableName, 'Bàn 9');
    expect(tableRepository.lastCreatedTableCapacity, 4);
    expect(
      tableRepository.loadTableGroupsCallCount,
      greaterThan(initialLoadCount),
    );
    expect(find.text('Thêm bàn thành công!'), findsOneWidget);
  });

  testWidgets('add table tile is disabled without TABLE.CREATE', (
    tester,
  ) async {
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

    final addTableTile = await _scrollToFirstAddTableTile(tester);

    final addTile = tester.widget<AddTableTile>(addTableTile);
    expect(addTile.isEnabled, isFalse);

    await tester.tap(addTableTile);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('table_form_submit_button')), findsNothing);
    expect(tableRepository.createTableCallCount, 0);
  });
}

Future<Finder> _scrollToFirstAddTableTile(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, -500));
  await tester.pumpAndSettle();
  return find.byType(AddTableTile).first;
}

Future<void> _completeDisplayOrderSave(
  WidgetTester tester,
  _FakeTableManagementRepository tableRepository,
  int index,
) async {
  tableRepository.updateAreaDisplayOrderCompleters[index].complete();
  await tester.pump();
  await tester.pump();
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
        createTableUseCaseProvider.overrideWithValue(
          CreateTableUseCase(tableRepository),
        ),
        updateAreaUseCaseProvider.overrideWithValue(
          UpdateAreaUseCase(tableRepository),
        ),
        updateTableUseCaseProvider.overrideWithValue(
          UpdateTableUseCase(tableRepository),
        ),
        updateAreaDisplayOrderUseCaseProvider.overrideWithValue(
          UpdateAreaDisplayOrderUseCase(tableRepository),
        ),
        deleteAreaUseCaseProvider.overrideWithValue(
          DeleteAreaUseCase(tableRepository),
        ),
        ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TableManagementPage(storeId: 5),
      ),
    ),
  );
}

Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  required List<StorePermission> permissions,
  required _FakeTableManagementRepository tableRepository,
}) async {
  final workspaceRepository = _FakeWorkspaceRepository(permissions);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(workspaceRepository, tableRepository),
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TableSettingsPage(storeId: 5),
      ),
    ),
  );
}

Future<void> _pumpRoutedPage(
  WidgetTester tester, {
  required List<StorePermission> permissions,
  required _FakeTableManagementRepository tableRepository,
}) async {
  final workspaceRepository = _FakeWorkspaceRepository(permissions);
  final router = GoRouter(
    initialLocation: '/stores/5/tables',
    routes: [
      GoRoute(
        path: '/stores/:storeId/tables',
        name: 'store-table-management',
        builder: (context, state) => const TableManagementPage(storeId: 5),
      ),
      GoRoute(
        path: '/stores/:storeId/tables/settings',
        name: 'store-table-settings',
        builder: (context, state) => const TableSettingsPage(storeId: 5),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(workspaceRepository, tableRepository),
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
}

List<Override> _overrides(
  _FakeWorkspaceRepository workspaceRepository,
  _FakeTableManagementRepository tableRepository,
) {
  return [
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
    createTableUseCaseProvider.overrideWithValue(
      CreateTableUseCase(tableRepository),
    ),
    updateAreaUseCaseProvider.overrideWithValue(
      UpdateAreaUseCase(tableRepository),
    ),
    updateTableUseCaseProvider.overrideWithValue(
      UpdateTableUseCase(tableRepository),
    ),
    updateAreaDisplayOrderUseCaseProvider.overrideWithValue(
      UpdateAreaDisplayOrderUseCase(tableRepository),
    ),
    deleteAreaUseCaseProvider.overrideWithValue(
      DeleteAreaUseCase(tableRepository),
    ),
    ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
  ];
}

List<Override> _lastActiveStoreOverrides(_FakeLastActiveStoreStorage storage) {
  return [
    loadLastActiveStoreUseCaseProvider.overrideWithValue(
      LoadLastActiveStoreUseCase(storage),
    ),
    saveLastActiveStoreUseCaseProvider.overrideWithValue(
      SaveLastActiveStoreUseCase(storage),
    ),
    clearLastActiveStoreUseCaseProvider.overrideWithValue(
      ClearLastActiveStoreUseCase(storage),
    ),
  ];
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

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  int? lastStoreId;

  _FakeLastActiveStoreStorage({int? initialStoreId})
    : lastStoreId = initialStoreId;

  @override
  Future<int?> getLastActiveStoreId() async {
    return lastStoreId;
  }

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    lastStoreId = storeId;
  }

  @override
  Future<void> clearLastActiveStoreId() async {
    lastStoreId = null;
  }
}

class _FakeTableManagementRepository implements TableManagementRepository {
  int loadAreasCallCount = 0;
  int loadTableGroupsCallCount = 0;
  int createAreaCallCount = 0;
  int createTableCallCount = 0;
  int updateAreaCallCount = 0;
  int updateTableCallCount = 0;
  int updateAreaDisplayOrderCallCount = 0;
  int deleteAreaCallCount = 0;
  bool failUpdateAreaDisplayOrder = false;
  bool holdUpdateAreaDisplayOrder = false;
  final updateAreaDisplayOrderRequests = <String>[];
  final updateAreaDisplayOrderCompleters = <Completer<void>>[];
  int? lastAreaId;
  int? lastCreatedTableStoreId;
  int? lastCreatedTableAreaId;
  String? lastCreatedTableName;
  int? lastCreatedTableCapacity;
  int? lastUpdatedTableId;
  int? lastUpdatedTableAreaId;
  String? lastUpdatedTableName;
  int? lastUpdatedTableCapacity;

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
  Future<DiningTable> createTable({
    required int storeId,
    required int areaId,
    required String name,
    required int capacity,
  }) async {
    createTableCallCount += 1;
    lastCreatedTableStoreId = storeId;
    lastCreatedTableAreaId = areaId;
    lastCreatedTableName = name;
    lastCreatedTableCapacity = capacity;

    return DiningTable(
      id: 99,
      storeId: storeId,
      areaId: areaId,
      name: name,
      capacity: capacity,
      status: TableStatus.available,
      isDeleted: false,
    );
  }

  @override
  Future<DiningTable> updateTable({
    required int tableId,
    required int areaId,
    required String name,
    required int capacity,
  }) async {
    updateTableCallCount += 1;
    lastUpdatedTableId = tableId;
    lastUpdatedTableAreaId = areaId;
    lastUpdatedTableName = name;
    lastUpdatedTableCapacity = capacity;

    return DiningTable(
      id: tableId,
      storeId: 5,
      areaId: areaId,
      name: name,
      capacity: capacity,
      status: TableStatus.available,
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
    updateAreaDisplayOrderRequests.add('$areaId:$displayOrder');
    if (failUpdateAreaDisplayOrder) {
      throw Exception('Không thể lưu thứ tự khu vực');
    }

    if (holdUpdateAreaDisplayOrder) {
      final completer = Completer<void>();
      updateAreaDisplayOrderCompleters.add(completer);
      await completer.future;
    }

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
