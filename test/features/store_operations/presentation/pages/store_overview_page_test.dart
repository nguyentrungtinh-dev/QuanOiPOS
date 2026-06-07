import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/store_operations/presentation/pages/store_feature_search_page.dart';
import 'package:quan_oi/features/store_operations/presentation/pages/store_overview_page.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/exceptions/store_access_denied_exception.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('store overview renders dashboard and active overview nav', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [
          StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
          StorePermission(permissionId: 3, code: 'STORE.UPDATE'),
          StorePermission(permissionId: 4, code: 'INVENTORY.VIEW'),
          StorePermission(permissionId: 5, code: 'AREA.VIEW'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FPT Shipper Vip'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    expect(
      find.text('Bạn chưa tạo hóa đơn để phân tích lãi lỗ'),
      findsOneWidget,
    );
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền xem quản lý kho'), findsNothing);
    expect(find.text('Quản lý bàn'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền xem quản lý bàn'), findsNothing);
  });

  testWidgets('store overview blocks dashboard without DASHBOARD.VIEW', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 2, code: 'STORE.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền xem tổng quan'), findsOneWidget);
    expect(find.text('Tổng quan hôm nay'), findsNothing);
  });

  testWidgets('store overview disables missing permission actions', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền xem quản lý bàn'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền xem quản lý kho'), findsNothing);
    expect(find.text('Bạn chưa có quyền cập nhật cửa hàng'), findsWidgets);
  });

  testWidgets('store overview enables inventory without INVENTORY.VIEW', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quản lý kho'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền xem quản lý kho'), findsNothing);
  });

  testWidgets('product item navigates to product management route', (
    tester,
  ) async {
    final repository = const _FakeWorkspaceRepository(
      permissions: [
        StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
        StorePermission(permissionId: 2, code: 'PRODUCT.VIEW'),
      ],
    );
    final router = GoRouter(
      initialLocation: '/stores/5',
      routes: [
        GoRoute(
          path: '/stores/:storeId',
          name: RouteNames.storeOverview,
          builder: (context, state) => const StoreOverviewPage(storeId: 5),
        ),
        GoRoute(
          path: '/stores/:storeId/products',
          name: RouteNames.storeProductManagement,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Product route opened'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FixedAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                accountType: AccountType.storeUser,
                fullName: 'Test User',
                email: 'user@quanoi.test',
              ),
            ),
          ),
          loadStoreAccessContextUseCaseProvider.overrideWithValue(
            LoadStoreAccessContextUseCase(repository),
          ),
          loadMyStoresUseCaseProvider.overrideWithValue(
            LoadMyStoresUseCase(repository),
          ),
          ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    addTearDown(router.dispose);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Sản phẩm').last);
    await tester.pumpAndSettle();

    expect(find.text('Product route opened'), findsOneWidget);
  });

  testWidgets(
    'inventory tile navigates to mock stock page without permission',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5');
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quản lý kho'));
      await tester.pumpAndSettle();

      expect(find.text('Quản lý kho'), findsOneWidget);
      expect(find.text('Nhập kho'), findsOneWidget);
      expect(find.text('Xuất kho'), findsOneWidget);
      expect(find.text('Sổ kho'), findsOneWidget);
      expect(find.text('Kiểm kho'), findsOneWidget);
      expect(find.text('Tồn kho'), findsOneWidget);
      expect(find.text('In mã vạch'), findsOneWidget);

      await tester.tap(find.text('Tồn kho'));
      await tester.pumpAndSettle();

      expect(find.text('Tìm tên, mã SKU, ...'), findsOneWidget);
      expect(find.text('Sản phẩm'), findsNothing);
      expect(find.text('Tồn kho'), findsNothing);
      expect(find.text('Bán kèm'), findsNothing);
      expect(find.text('Danh mục'), findsOneWidget);
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('Sắp xếp'), findsOneWidget);
      expect(
        find.textContaining('Số lượng 158', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Giá trị tồn 84.000', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Thăng Long'), findsOneWidget);
      expect(find.text('SP0048'), findsOneWidget);
      expect(find.text('Kho: 9/9'), findsOneWidget);
    },
  );

  testWidgets(
    'inventory import tile navigates to mock import page without permission',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5/inventory');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nhập kho'));
      await tester.pumpAndSettle();

      expect(find.text('Sổ nhập hàng'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chờ xác nhận'), findsOneWidget);
      expect(find.text('Chưa thanh toán'), findsOneWidget);
      expect(find.text('Hoàn thành'), findsWidgets);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.text('Phân loại'), findsOneWidget);
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('#NH265'), findsOneWidget);
      expect(find.text('13:01 27/05/26'), findsOneWidget);
      expect(find.text('3.500'), findsOneWidget);
      expect(find.text('Đã thanh toán'), findsWidgets);
      expect(find.text('Tạo nhập hàng'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);

      await tester.tap(find.text('Tạo nhập hàng'));
      await tester.pumpAndSettle();

      expect(find.text('Nhập sản phẩm'), findsOneWidget);
      expect(find.text('Nhập nguyên liệu'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('inventory_import_create_menu_backdrop')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhập sản phẩm'), findsNothing);

      await tester.tap(find.text('Tạo nhập hàng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhập sản phẩm'));
      await tester.pumpAndSettle();

      expect(find.text('Nhập hàng'), findsOneWidget);
      expect(find.text('Sản phẩm'), findsOneWidget);
      expect(find.text('Danh mục'), findsOneWidget);
      expect(find.text('Revive'), findsOneWidget);
      expect(find.text('SP0098  |  Còn: 4'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsNothing);

      await tester.tap(
        find.byKey(const Key('inventory_import_product_add_SP0098')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inventory_import_product_stepper_SP0098')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_import_product_quantity_SP0098')),
        findsOneWidget,
      );
      expect(find.text('1 SP'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('inventory_import_products_continue_action')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tạo nhập hàng'), findsOneWidget);
      expect(find.text('Chọn nhà cung cấp'), findsOneWidget);
      expect(find.text('Sản phẩm (1)'), findsNothing);
      expect(find.text('Revive'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory_import_product_price_SP0098')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_import_product_quantity_draft_SP0098')),
        findsOneWidget,
      );
      expect(find.text('Tổng số lượng'), findsOneWidget);
      expect(find.text('Tổng cộng'), findsOneWidget);
      expect(find.text('Nhập hàng'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('inventory_import_product_price_SP0098')),
        '10000',
      );
      await tester.pumpAndSettle();

      expect(find.text('10000'), findsWidgets);

      await tester.tap(
        find.byKey(const Key('inventory_import_draft_add_product_action')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhập hàng'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory_import_product_stepper_SP0098')),
        findsOneWidget,
      );
      expect(find.text('1 SP'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('inventory_import_products_continue_action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('inventory_import_draft_back_action')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhập hàng'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory_import_product_stepper_SP0098')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'inventory export tile navigates to mock export page without permission',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5/inventory');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xuất kho'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/stores/5/inventory/exports');
      expect(find.text('Sổ xuất hàng'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Đang xử lý'), findsOneWidget);
      expect(find.text('Hoàn thành'), findsWidgets);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.text('Phân loại'), findsOneWidget);
      expect(find.text('#XH1948'), findsOneWidget);
      expect(find.text('09:05 22/05/26'), findsOneWidget);
      expect(find.text('Tạo bởi Lê Minh An'), findsOneWidget);
      expect(find.text('Tổng cộng'), findsOneWidget);
      expect(find.text('Tạo xuất hàng'), findsNothing);
      expect(
        find.byKey(const Key('inventory_export_create_action')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'inventory export create opens mock product selection and cart bar',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5/inventory/exports');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory_export_create_action')));
      await tester.pumpAndSettle();

      expect(find.text('Xuất sản phẩm'), findsOneWidget);
      expect(find.text('Xuất nguyên liệu'), findsOneWidget);
      expect(find.text('Bổ sung nguyên vật liệu'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('inventory_export_create_product_action')),
      );
      await tester.pumpAndSettle();

      expect(
        router.state.matchedLocation,
        '/stores/5/inventory/exports/products',
      );
      expect(find.text('Xuất hàng'), findsOneWidget);
      expect(find.text('Sản phẩm'), findsOneWidget);
      expect(find.text('Danh mục'), findsOneWidget);
      expect(find.text('Revive'), findsOneWidget);
      expect(find.text('SP0098  |  Còn: 4'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsNothing);

      await tester.tap(
        find.byKey(const Key('inventory_export_product_add_SP0098')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inventory_export_product_stepper_SP0098')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_export_product_quantity_SP0098')),
        findsOneWidget,
      );
      expect(find.text('1 SP'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('inventory_export_product_increment_SP0098')),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 SP'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('inventory_export_product_add_SP0082')),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 SP'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('inventory_export_products_continue_action')),
      );
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/stores/5/inventory/exports/draft');
      expect(find.text('Tạo phiếu xuất hàng'), findsOneWidget);
      expect(find.text('Thêm sản phẩm'), findsOneWidget);
      expect(find.text('Revive'), findsOneWidget);
      expect(find.text('SP0098'), findsOneWidget);
      expect(find.text('Tổng số lượng'), findsOneWidget);
      expect(find.text('Tổng cộng'), findsOneWidget);
      expect(find.text('Hoàn thành'), findsOneWidget);
      expect(find.text('Nguyên vật liệu'), findsNothing);
      expect(find.text('Lưu phiếu'), findsNothing);
      final totalQuantityText = tester.widget<Text>(
        find.byKey(const Key('inventory_export_draft_total_quantity')),
      );
      final productCountText = tester.widget<Text>(
        find.byKey(const Key('inventory_export_draft_product_count')),
      );
      expect(totalQuantityText.data, '3');
      expect(productCountText.data, '2');

      await tester.tap(
        find.byKey(const Key('inventory_export_draft_add_product_action')),
      );
      await tester.pumpAndSettle();

      expect(
        router.state.matchedLocation,
        '/stores/5/inventory/exports/products',
      );
      expect(
        find.byKey(const Key('inventory_export_product_stepper_SP0098')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_export_product_stepper_SP0082')),
        findsOneWidget,
      );
      expect(find.text('3 SP'), findsOneWidget);
    },
  );

  testWidgets('inventory export supplement action opens mock material flow', (
    tester,
  ) async {
    final repository = const _FakeWorkspaceRepository(
      permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/exports');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inventory_export_create_action')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('inventory_export_supplement_ingredient_action')),
    );
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      '/stores/5/inventory/exports/supplement-materials',
    );
    expect(find.text('Bổ sung nguyên vật liệu'), findsOneWidget);
    expect(find.text('Nguyên vật liệu'), findsOneWidget);
    expect(find.text('Nhóm nguyên vật liệu'), findsOneWidget);
    expect(find.text('Đường'), findsOneWidget);
    expect(find.text('NVL0001  |  Còn: 12 kg'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsNothing);

    await tester.tap(
      find.byKey(const Key('inventory_export_supplement_material_add_NVL0001')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key('inventory_export_supplement_material_stepper_NVL0001'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('inventory_export_supplement_material_quantity_NVL0001'),
      ),
      findsOneWidget,
    );
    expect(find.text('1 NVL'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const Key('inventory_export_supplement_material_increment_NVL0001'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 NVL'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('inventory_export_supplement_material_add_NVL0002')),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 NVL'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const Key('inventory_export_supplement_materials_continue_action'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      '/stores/5/inventory/exports/supplement-materials/draft',
    );
    expect(find.text('Tạo phiếu bổ sung nguyên vật liệu'), findsOneWidget);
    expect(find.text('Thêm nguyên vật liệu'), findsOneWidget);
    expect(find.text('Đường'), findsOneWidget);
    expect(find.text('NVL0001'), findsOneWidget);
    expect(find.text('Tổng số lượng'), findsOneWidget);
    expect(find.text('Tổng cộng'), findsOneWidget);
    expect(find.text('Hoàn thành'), findsOneWidget);
    final totalQuantityText = tester.widget<Text>(
      find.byKey(
        const Key('inventory_export_supplement_material_draft_total_quantity'),
      ),
    );
    final materialCountText = tester.widget<Text>(
      find.byKey(
        const Key('inventory_export_supplement_material_draft_material_count'),
      ),
    );
    expect(totalQuantityText.data, '3');
    expect(materialCountText.data, '2');

    await tester.tap(
      find.byKey(
        const Key('inventory_export_supplement_material_draft_add_action'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      '/stores/5/inventory/exports/supplement-materials',
    );
    expect(
      find.byKey(
        const Key('inventory_export_supplement_material_stepper_NVL0001'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('inventory_export_supplement_material_stepper_NVL0002'),
      ),
      findsOneWidget,
    );
    expect(find.text('3 NVL'), findsOneWidget);
  });

  testWidgets('inventory export ingredient action opens mock ingredient flow', (
    tester,
  ) async {
    final repository = const _FakeWorkspaceRepository(
      permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/exports');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inventory_export_create_action')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('inventory_export_create_ingredient_action')),
    );
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      '/stores/5/inventory/exports/ingredients',
    );
    expect(find.text('Xuất nguyên liệu'), findsOneWidget);
    expect(find.text('Nguyên liệu'), findsOneWidget);
    expect(find.text('Nhóm nguyên liệu'), findsOneWidget);
    expect(find.text('Đường'), findsOneWidget);
    expect(find.text('NL0001  |  Còn: 12 kg'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsNothing);

    await tester.tap(
      find.byKey(const Key('inventory_export_ingredient_add_NL0001')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventory_export_ingredient_stepper_NL0001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventory_export_ingredient_quantity_NL0001')),
      findsOneWidget,
    );
    expect(find.text('1 NL'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('inventory_export_ingredient_increment_NL0001')),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 NL'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('inventory_export_ingredient_add_NL0002')),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 NL'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('inventory_export_ingredients_continue_action')),
    );
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      '/stores/5/inventory/exports/ingredients/draft',
    );
    expect(find.text('Tạo phiếu xuất nguyên liệu'), findsOneWidget);
    expect(find.text('Thêm nguyên liệu'), findsOneWidget);
    expect(find.text('Đường'), findsOneWidget);
    expect(find.text('NL0001'), findsOneWidget);
    expect(find.text('Tổng số lượng'), findsOneWidget);
    expect(find.text('Tổng cộng'), findsOneWidget);
    expect(find.text('Hoàn thành'), findsOneWidget);
    final totalQuantityText = tester.widget<Text>(
      find.byKey(const Key('inventory_export_ingredient_draft_total_quantity')),
    );
    final ingredientCountText = tester.widget<Text>(
      find.byKey(
        const Key('inventory_export_ingredient_draft_ingredient_count'),
      ),
    );
    expect(totalQuantityText.data, '3');
    expect(ingredientCountText.data, '2');

    await tester.tap(
      find.byKey(const Key('inventory_export_ingredient_draft_add_action')),
    );
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      '/stores/5/inventory/exports/ingredients',
    );
    expect(
      find.byKey(const Key('inventory_export_ingredient_stepper_NL0001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventory_export_ingredient_stepper_NL0002')),
      findsOneWidget,
    );
    expect(find.text('3 NL'), findsOneWidget);
  });

  testWidgets('inventory import ingredient action opens mock ingredient flow', (
    tester,
  ) async {
    final repository = const _FakeWorkspaceRepository(
      permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/imports');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('inventory_import_import_ingredient_action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhập nguyên liệu'), findsOneWidget);
    expect(find.text('Nguyên liệu'), findsOneWidget);
    expect(find.text('Nhóm nguyên liệu'), findsOneWidget);
    expect(find.text('Đường'), findsOneWidget);
    expect(find.text('NL0001  |  Còn: 12 kg'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsNothing);

    await tester.tap(
      find.byKey(const Key('inventory_import_ingredient_add_NL0001')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventory_import_ingredient_stepper_NL0001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventory_import_ingredient_quantity_NL0001')),
      findsOneWidget,
    );
    expect(find.text('1 NL'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('inventory_import_ingredients_continue_action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tạo nhập nguyên liệu'), findsOneWidget);
    expect(find.text('Chọn nhà cung cấp'), findsOneWidget);
    expect(find.text('+ Thêm nguyên liệu'), findsOneWidget);
    expect(find.text('Đường'), findsOneWidget);
    expect(
      find.byKey(const Key('inventory_import_ingredient_price_NL0001')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('inventory_import_ingredient_quantity_draft_NL0001'),
      ),
      findsOneWidget,
    );
    expect(find.text('Tổng số lượng'), findsOneWidget);
    expect(find.text('Tổng cộng'), findsOneWidget);
    expect(find.text('Nhập nguyên liệu'), findsOneWidget);
  });

  testWidgets(
    'inventory ledger tile navigates to mock ledger page without permission',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5/inventory');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sổ kho'));
      await tester.pumpAndSettle();

      expect(find.text('Sổ kho'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.text('Phân loại'), findsOneWidget);
      expect(find.text('Loại hàng'), findsOneWidget);
      expect(find.text('Tồn đầu kỳ'), findsOneWidget);
      expect(find.text('106.000 đ'), findsOneWidget);
      expect(find.text('Nhập trong kỳ'), findsOneWidget);
      expect(find.text('87.500 đ'), findsOneWidget);
      expect(find.text('Xuất trong kỳ'), findsOneWidget);
      expect(find.text('59.500 đ'), findsOneWidget);
      expect(find.text('Tồn cuối kỳ'), findsOneWidget);
      expect(find.text('134.000 đ'), findsOneWidget);
      expect(find.text('HÔM NAY'), findsOneWidget);
      expect(find.text('Thăng Long'), findsWidgets);
      expect(find.text('SP0048'), findsWidgets);
      expect(find.text('#XH2074 - Bán hàng'), findsOneWidget);
      expect(find.text('SL: -1'), findsWidgets);
      expect(find.text('Xuất hàng'), findsOneWidget);
      expect(find.text('Kiểm kho'), findsOneWidget);
      expect(find.text('Nhập hàng'), findsOneWidget);
    },
  );

  testWidgets('inventory ledger page keeps access error state', (tester) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/ledger');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('106.000 đ'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('inventory import page keeps access error state', (tester) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/imports');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('#NH265'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('inventory export page keeps access error state', (tester) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/exports');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('#XH1948'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('inventory export products page keeps access error state', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/exports/products');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Revive'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('inventory export draft page keeps access error state', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/exports/draft');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Tạo phiếu xuất hàng'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('inventory export ingredients page keeps access error state', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/exports/ingredients');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Đường'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets(
    'inventory export ingredient draft page keeps access error state',
    (tester) async {
      final repository = _FakeWorkspaceRepository(
        permissions: const [],
        accessError: Exception('Store access failed'),
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5/inventory/exports/ingredients/draft');
      await tester.pumpAndSettle();

      expect(find.text('Store access failed'), findsOneWidget);
      expect(find.text('Tạo phiếu xuất nguyên liệu'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  testWidgets(
    'inventory export supplement materials page keeps access error state',
    (tester) async {
      final repository = _FakeWorkspaceRepository(
        permissions: const [],
        accessError: Exception('Store access failed'),
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5/inventory/exports/supplement-materials');
      await tester.pumpAndSettle();

      expect(find.text('Store access failed'), findsOneWidget);
      expect(find.text('Đường'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  testWidgets(
    'inventory export supplement material draft page keeps access error state',
    (tester) async {
      final repository = _FakeWorkspaceRepository(
        permissions: const [],
        accessError: Exception('Store access failed'),
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5/inventory/exports/supplement-materials/draft');
      await tester.pumpAndSettle();

      expect(find.text('Store access failed'), findsOneWidget);
      expect(find.text('Tạo phiếu bổ sung nguyên vật liệu'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  testWidgets('inventory import ingredients page keeps access error state', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/imports/ingredients');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Đường'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets(
    'inventory check tile navigates to mock empty page without permission',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5/inventory');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiểm kho'));
      await tester.pumpAndSettle();

      expect(find.text('Kiểm kho'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Đang kiểm kho'), findsOneWidget);
      expect(find.text('Đã cân bằng'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.text('Phân loại'), findsOneWidget);
      expect(find.text('Nhân viên'), findsOneWidget);
      expect(find.text('Bạn chưa có phiếu kiểm kho nào!'), findsOneWidget);
      expect(find.text('Tạo kiểm kho'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);

      await tester.tap(find.text('Tạo kiểm kho'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/stores/5/inventory/checks/create');
      expect(find.text('Tìm/Chọn sản phẩm, SKU...'), findsOneWidget);
      expect(find.text('Sản phẩm'), findsOneWidget);
      expect(find.text('Nguyên vật liệu'), findsOneWidget);
      expect(find.text('Thăng Long'), findsOneWidget);
      expect(find.text('SP0048'), findsOneWidget);
      expect(find.text('Kho: 9'), findsOneWidget);

      await tester.tap(find.text('Thăng Long'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/stores/5/inventory/checks/draft');
      expect(find.text('Tạo phiếu kiểm kho'), findsOneWidget);
      expect(find.text('Tìm/Chọn sản phẩm, SKU...'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Đã cân bằng'), findsOneWidget);
      expect(find.text('Lệch'), findsWidgets);
      expect(find.text('Trống'), findsOneWidget);
      expect(find.text('Thăng Long'), findsOneWidget);
      expect(find.text('SP0048'), findsOneWidget);
      expect(find.text('Kho hệ thống: 9'), findsOneWidget);
      expect(find.text('Lệch: -9'), findsOneWidget);
      expect(find.text('Lưu phiếu'), findsOneWidget);
      expect(find.text('Hoàn thành'), findsOneWidget);
      final actualQuantityText = tester.widget<Text>(
        find.byKey(const Key('inventory_check_draft_actual_quantity')),
      );
      final systemQuantityText = tester.widget<Text>(
        find.byKey(const Key('inventory_check_draft_system_quantity')),
      );
      final differenceQuantityText = tester.widget<Text>(
        find.byKey(const Key('inventory_check_draft_difference_quantity')),
      );
      expect(actualQuantityText.data, '0');
      expect(systemQuantityText.data, '9');
      expect(differenceQuantityText.data, '9');

      await tester.tap(
        find.byKey(const Key('inventory_check_draft_increment_SP0048')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lệch: -8'), findsOneWidget);
      final updatedActualQuantityText = tester.widget<Text>(
        find.byKey(const Key('inventory_check_draft_actual_quantity')),
      );
      final updatedDifferenceQuantityText = tester.widget<Text>(
        find.byKey(const Key('inventory_check_draft_difference_quantity')),
      );
      expect(updatedActualQuantityText.data, '1');
      expect(updatedDifferenceQuantityText.data, '8');

      router.go('/stores/5/inventory/checks/create');
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('inventory_check_create_ingredients_tab')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đường'), findsOneWidget);
      expect(find.text('NL0001'), findsOneWidget);
      expect(find.text('Kho: 12 kg'), findsOneWidget);

      await tester.tap(find.text('Đường'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/stores/5/inventory/checks/draft');
      expect(find.text('Đường'), findsOneWidget);
      expect(find.text('NL0001'), findsOneWidget);
      expect(find.text('Kho hệ thống: 12 kg'), findsOneWidget);
    },
  );

  testWidgets('inventory check page keeps access error state', (tester) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/checks');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Bạn chưa có phiếu kiểm kho nào!'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('inventory check create page keeps access error state', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/checks/create');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Thăng Long'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets(
    'inventory check draft without selected item shows missing state',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5/inventory/checks/draft');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/stores/5/inventory/checks/draft');
      expect(find.text('Chưa chọn hàng kiểm kho'), findsOneWidget);
      expect(find.text('Chọn hàng kiểm kho'), findsOneWidget);
      expect(find.text('Thăng Long'), findsNothing);

      await tester.tap(find.text('Chọn hàng kiểm kho'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/stores/5/inventory/checks/create');
    },
  );

  testWidgets('inventory check draft page keeps access error state', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/checks/draft');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Tạo phiếu kiểm kho'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('stock page keeps access error state instead of mock content', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/stock');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Thăng Long'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('store header opens drawer with active store and account menu', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('store_workspace_header_search_pill')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('store_workspace_header_logo_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('store_workspace_drawer')), findsOneWidget);
    expect(find.byKey(const Key('switch_store_5')), findsOneWidget);
    expect(find.text('Buffet Poseidon'), findsOneWidget);
    expect(find.text('Gói dịch vụ của tôi'), findsOneWidget);
    expect(find.text('Cửa hàng'), findsOneWidget);
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
    expect(find.text('Cài đặt ứng dụng'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
  });

  testWidgets('store search pill opens feature search suggestions', (
    tester,
  ) async {
    await _pumpFeatureSearchRouter(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [
          StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
          StorePermission(permissionId: 2, code: 'PRODUCT.VIEW'),
        ],
      ),
    );

    await tester.tap(
      find.byKey(const Key('store_workspace_header_search_pill')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gợi ý tính năng'), findsOneWidget);
    expect(find.text('Bán hàng'), findsOneWidget);
    expect(find.text('Sản phẩm'), findsOneWidget);
    expect(find.text('Thu chi'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
  });

  testWidgets(
    'feature search filters and opens product route with permission',
    (tester) async {
      await _pumpFeatureSearchRouter(
        tester,
        const _FakeWorkspaceRepository(
          permissions: [
            StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
            StorePermission(permissionId: 2, code: 'PRODUCT.VIEW'),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const Key('store_workspace_header_search_pill')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('store_feature_search_field')),
        'sản',
      );
      await tester.pumpAndSettle();

      expect(find.text('Kết quả phù hợp'), findsOneWidget);
      expect(find.text('Sản phẩm'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('store_feature_search_item_products')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Product route opened'), findsOneWidget);
    },
  );

  testWidgets('feature search keeps product disabled without permission', (
    tester,
  ) async {
    await _pumpFeatureSearchRouter(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );

    await tester.tap(
      find.byKey(const Key('store_workspace_header_search_pill')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('store_feature_search_field')),
      'sản',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('store_feature_search_item_products')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sản phẩm'), findsOneWidget);
    expect(find.text('Product route opened'), findsNothing);
  });

  testWidgets('feature search handles access error state', (tester) async {
    await _pumpFeatureSearchRouter(
      tester,
      _FakeWorkspaceRepository(
        permissions: const [],
        accessError: Exception('Store access failed'),
      ),
      initialLocation: '/stores/5/search',
    );

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Gợi ý tính năng'), findsNothing);
  });

  testWidgets('feature search handles forbidden state', (tester) async {
    await _pumpFeatureSearchRouter(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [],
        accessError: StoreAccessDeniedException('No store access'),
      ),
      initialLocation: '/stores/5/search',
    );

    expect(find.text('No store access'), findsOneWidget);
    expect(find.text('Gợi ý tính năng'), findsNothing);
  });

  testWidgets('selecting current store closes drawer without route reload', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('store_workspace_header_logo_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch_store_5')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('store_workspace_drawer')), findsNothing);
    expect(find.text('FPT Shipper Vip'), findsOneWidget);
  });

  testWidgets(
    'selecting another active store navigates to that store overview',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final lastActiveStoreStorage = _FakeLastActiveStoreStorage();
      final container = _buildRouterContainer(
        repository,
        lastActiveStoreStorage: lastActiveStoreStorage,
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/stores/5');
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('store_workspace_header_logo_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('switch_store_2')));
      await tester.pumpAndSettle();

      expect(find.text('Buffet Poseidon'), findsOneWidget);
      expect(find.text('FPT Shipper Vip'), findsNothing);
      expect(lastActiveStoreStorage.lastStoreId, 2);
    },
  );

  testWidgets('store drawer account menu opens my stores route', (
    tester,
  ) async {
    final repository = const _FakeWorkspaceRepository(
      permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5');
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('store_workspace_header_logo_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cửa hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Danh sách cửa hàng'), findsOneWidget);
    expect(find.text('Buffet Poseidon'), findsOneWidget);
    expect(find.text('Tổng quan hôm nay'), findsNothing);
  });

  testWidgets('store load error offers navigation back to my stores', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [
        StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
      ],
      accessError: Exception(
        'Tai khoan nguoi dung khong du quyen de thuc hien yeu cau nay!',
      ),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5');
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tai khoan nguoi dung khong du quyen de thuc hien yeu cau nay!',
      ),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Về danh sách cửa hàng'), findsOneWidget);

    await tester.tap(find.text('Về danh sách cửa hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Danh sách cửa hàng'), findsOneWidget);
    expect(find.text('FPT Shipper Vip'), findsOneWidget);
  });

  testWidgets('inactive store is disabled in switcher', (tester) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('store_workspace_header_logo_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch_store_6')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('store_workspace_drawer')), findsOneWidget);
    expect(find.byKey(const Key('switch_store_6')), findsOneWidget);
  });
}

Future<void> _pumpFeatureSearchRouter(
  WidgetTester tester,
  _FakeWorkspaceRepository repository, {
  String initialLocation = '/stores/5',
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/stores/:storeId/search',
        name: RouteNames.storeFeatureSearch,
        builder: (context, state) => const StoreFeatureSearchPage(storeId: 5),
      ),
      GoRoute(
        path: '/stores/:storeId',
        name: RouteNames.storeOverview,
        builder: (context, state) => const StoreOverviewPage(storeId: 5),
      ),
      GoRoute(
        path: '/stores/:storeId/products',
        name: RouteNames.storeProductManagement,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Product route opened'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FixedAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              accountType: AccountType.storeUser,
              fullName: 'Test User',
              email: 'user@quanoi.test',
            ),
          ),
        ),
        loadStoreAccessContextUseCaseProvider.overrideWithValue(
          LoadStoreAccessContextUseCase(repository),
        ),
        loadMyStoresUseCaseProvider.overrideWithValue(
          LoadMyStoresUseCase(repository),
        ),
        ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpOverview(
  WidgetTester tester,
  _FakeWorkspaceRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FixedAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              accountType: AccountType.storeUser,
              fullName: 'Test User',
              email: 'user@quanoi.test',
            ),
          ),
        ),
        loadStoreAccessContextUseCaseProvider.overrideWithValue(
          LoadStoreAccessContextUseCase(repository),
        ),
        loadMyStoresUseCaseProvider.overrideWithValue(
          LoadMyStoresUseCase(repository),
        ),
        ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const StoreOverviewPage(storeId: 5),
      ),
    ),
  );
}

ProviderContainer _buildRouterContainer(
  _FakeWorkspaceRepository repository, {
  _FakeLastActiveStoreStorage? lastActiveStoreStorage,
}) {
  final storeStorage = lastActiveStoreStorage ?? _FakeLastActiveStoreStorage();

  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          const AuthState(
            status: AuthStatus.authenticated,
            accountType: AccountType.storeUser,
            fullName: 'Test User',
            email: 'user@quanoi.test',
          ),
        ),
      ),
      loadStoreAccessContextUseCaseProvider.overrideWithValue(
        LoadStoreAccessContextUseCase(repository),
      ),
      loadMyStoresUseCaseProvider.overrideWithValue(
        LoadMyStoresUseCase(repository),
      ),
      ..._lastActiveStoreOverrides(storeStorage),
    ],
  );
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

class _FixedAuthNotifier extends AuthNotifier {
  final AuthState fixedState;

  _FixedAuthNotifier(this.fixedState);

  @override
  AuthState build() {
    return fixedState;
  }
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<StorePermission> permissions;
  final Exception? accessError;

  const _FakeWorkspaceRepository({required this.permissions, this.accessError});

  @override
  Future<List<Store>> loadMyStores() async {
    return _stores;
  }

  @override
  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  }) async {
    return _stores.first;
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    return _stores.firstWhere((store) => store.id == storeId);
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return permissions;
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    final error = accessError;
    if (error != null) {
      throw error;
    }

    return StoreAccessContext(
      store: await loadStoreById(storeId),
      permissions: await loadMyStorePermissions(storeId),
    );
  }

  @override
  Future<StoreAccessContext?> loadCachedStoreAccessContext({
    required int accountId,
    required int storeId,
  }) async {
    return null;
  }

  @override
  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  }) async {}

  @override
  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  }) async {}

  @override
  Future<void> clearAllStoreAccessContextCache() async {}
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

const _stores = [
  Store(
    id: 5,
    ownerAccountId: 8,
    storeName: 'FPT Shipper Vip',
    phone: '0123456789',
    address: 'Gần Đại Học FPT',
    status: StoreStatus.active,
    isDeleted: false,
  ),
  Store(
    id: 2,
    ownerAccountId: 8,
    storeName: 'Buffet Poseidon',
    phone: '0961813466',
    address: 'TTTM Vincom Plaza',
    status: StoreStatus.active,
    isDeleted: false,
  ),
  Store(
    id: 6,
    ownerAccountId: 8,
    storeName: 'Kitchen Closed',
    phone: '0900000000',
    address: 'Quận 1',
    status: StoreStatus.closed,
    isDeleted: false,
  ),
];
